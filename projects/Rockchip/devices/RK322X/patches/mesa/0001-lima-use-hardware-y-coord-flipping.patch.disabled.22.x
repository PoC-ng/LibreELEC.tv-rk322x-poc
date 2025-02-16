From 0ee82b99080455bc8bb6fc206d37d52d0ed5d8d0 Mon Sep 17 00:00:00 2001
From: Erico Nunes <nunes.erico@gmail.com>
Date: Fri, 22 Apr 2022 21:35:32 +0200
Subject: [PATCH] mesa/st: add cap to skip ytransform

The wpos_ytransform pass adds some useful code that handles flipping
y coordinates for e.g. gl_FragCoord, but this may not be required in
case that can be done in hardware.
Add a cap that allows drivers to skip this pass if that will be
implemented in hardware.

Signed-off-by: Erico Nunes <nunes.erico@gmail.com>
---
 src/gallium/auxiliary/util/u_screen.c     | 3 +++
 src/gallium/include/pipe/p_defines.h      | 1 +
 src/mesa/state_tracker/st_glsl_to_nir.cpp | 5 +++--
 3 files changed, 7 insertions(+), 2 deletions(-)

diff --git a/src/gallium/auxiliary/util/u_screen.c b/src/gallium/auxiliary/util/u_screen.c
index 6ab60a639e7..dbd1c3a7fd6 100644
--- a/src/gallium/auxiliary/util/u_screen.c
+++ b/src/gallium/auxiliary/util/u_screen.c
@@ -490,6 +490,9 @@ u_pipe_screen_get_param_defaults(struct pipe_screen *pscreen,
    case PIPE_CAP_CLAMP_SPARSE_TEXTURE_LOD:
       return 0;
 
+   case PIPE_CAP_LOWER_WPOS_YTRANSFORM:
+      return 1;
+
    default:
       unreachable("bad PIPE_CAP_*");
    }
diff --git a/src/gallium/include/pipe/p_defines.h b/src/gallium/include/pipe/p_defines.h
index 50e0404a1e9..7655e4450cb 100644
--- a/src/gallium/include/pipe/p_defines.h
+++ b/src/gallium/include/pipe/p_defines.h
@@ -1009,6 +1009,7 @@ enum pipe_cap
    PIPE_CAP_QUERY_TIMESTAMP_BITS,
    /** For EGL_EXT_protected_content */
    PIPE_CAP_DEVICE_PROTECTED_CONTEXT,
+   PIPE_CAP_LOWER_WPOS_YTRANSFORM,

    PIPE_CAP_LAST,
    /* XXX do not add caps after PIPE_CAP_LAST! */
diff --git a/src/mesa/state_tracker/st_glsl_to_nir.cpp b/src/mesa/state_tracker/st_glsl_to_nir.cpp
index ac3e99ff336..bf4e9c57ccc 100644
--- a/src/mesa/state_tracker/st_glsl_to_nir.cpp
+++ b/src/mesa/state_tracker/st_glsl_to_nir.cpp
@@ -836,8 +836,9 @@ st_link_nir(struct gl_context *ctx,
       if (nir->info.stage == MESA_SHADER_VERTEX && !shader_program->data->spirv)
          nir_remap_dual_slot_attributes(nir, &shader->Program->DualSlotInputs);
 
-      NIR_PASS_V(nir, st_nir_lower_wpos_ytransform, shader->Program,
-                 st->screen);
+      if (st->screen->get_param(st->screen, PIPE_CAP_LOWER_WPOS_YTRANSFORM))
+         NIR_PASS_V(nir, st_nir_lower_wpos_ytransform, shader->Program,
+                    st->screen);
 
       NIR_PASS_V(nir, nir_lower_system_values);
       NIR_PASS_V(nir, nir_lower_compute_system_values, NULL);
-- 
GitLab

From e32b5cf2acdf3b538465704fca92ce12a2edfc73 Mon Sep 17 00:00:00 2001
From: Erico Nunes <nunes.erico@gmail.com>
Date: Fri, 22 Apr 2022 21:36:40 +0200
Subject: [PATCH] gallium: pass flip_y from st to gallium

For gallium drivers to perform flipping y coordinates in hardware,
this information is needed to detect when to do it or not.

Signed-off-by: Erico Nunes <nunes.erico@gmail.com>
---
 src/gallium/auxiliary/util/u_framebuffer.c   | 4 ++++
 src/gallium/include/pipe/p_state.h           | 1 +
 src/mesa/state_tracker/st_atom_framebuffer.c | 2 ++
 3 files changed, 7 insertions(+)

diff --git a/src/gallium/auxiliary/util/u_framebuffer.c b/src/gallium/auxiliary/util/u_framebuffer.c
index 36b6c14a4bb..dc3e2e849c6 100644
--- a/src/gallium/auxiliary/util/u_framebuffer.c
+++ b/src/gallium/auxiliary/util/u_framebuffer.c
@@ -102,6 +102,8 @@ util_copy_framebuffer_state(struct pipe_framebuffer_state *dst,
 
       dst->nr_cbufs = src->nr_cbufs;
 
+      dst->flip_y = src->flip_y;
+
       pipe_surface_reference(&dst->zsbuf, src->zsbuf);
    } else {
       dst->width = 0;
@@ -115,6 +117,8 @@ util_copy_framebuffer_state(struct pipe_framebuffer_state *dst,
 
       dst->nr_cbufs = 0;
 
+      dst->flip_y = 0;
+
       pipe_surface_reference(&dst->zsbuf, NULL);
    }
 }
diff --git a/src/gallium/include/pipe/p_state.h b/src/gallium/include/pipe/p_state.h
index 99ae182999c..c9f0cda9159 100644
--- a/src/gallium/include/pipe/p_state.h
+++ b/src/gallium/include/pipe/p_state.h
@@ -401,6 +401,7 @@ struct pipe_framebuffer_state
    struct pipe_surface *cbufs[PIPE_MAX_COLOR_BUFS];
 
    struct pipe_surface *zsbuf;      /**< Z/stencil buffer */
+   bool flip_y;
 };
 
 
diff --git a/src/mesa/state_tracker/st_atom_framebuffer.c b/src/mesa/state_tracker/st_atom_framebuffer.c
index 88ca3201b99..deadfecf89d 100644
--- a/src/mesa/state_tracker/st_atom_framebuffer.c
+++ b/src/mesa/state_tracker/st_atom_framebuffer.c
@@ -212,6 +212,8 @@ st_update_framebuffer_state( struct st_context *st )
    if (framebuffer.height == USHRT_MAX)
       framebuffer.height = 0;
 
+   framebuffer.flip_y = fb->FlipY;
+
    cso_set_framebuffer(st->cso_context, &framebuffer);
 
    st->state.fb_width = framebuffer.width;
-- 
GitLab

From 76004a2295302b3df7ae3b794a840ed1f51318de Mon Sep 17 00:00:00 2001
From: Erico Nunes <nunes.erico@gmail.com>
Date: Fri, 22 Apr 2022 21:37:09 +0200
Subject: [PATCH] lima: use hardware y coord flipping

Handling y coord flipping with the wpos_ytransform pass adds some
additional instructions that can have a performance hit on the Mali-4xx,
so skip this and use the hardware funcitonality for y flipping.
This overall reduces shader size and improves performance in programs
that uses gl_FragCoord.
It also removes the requirement of a lowering pass to double-negate
fddx and fddy and may fix some corner case bugs with those operations.

Signed-off-by: Erico Nunes <nunes.erico@gmail.com>
---
 src/gallium/drivers/lima/ir/pp/lower.c | 20 --------------------
 src/gallium/drivers/lima/lima_job.c    | 23 ++++++++++++++++++++---
 src/gallium/drivers/lima/lima_job.h    |  1 +
 src/gallium/drivers/lima/lima_screen.c |  3 +++
 4 files changed, 24 insertions(+), 23 deletions(-)

diff --git a/src/gallium/drivers/lima/ir/pp/lower.c b/src/gallium/drivers/lima/ir/pp/lower.c
index deed1c7f2c9..669bc930147 100644
--- a/src/gallium/drivers/lima/ir/pp/lower.c
+++ b/src/gallium/drivers/lima/ir/pp/lower.c
@@ -140,24 +140,6 @@ static bool ppir_lower_load(ppir_block *block, ppir_node *node)
    return true;
 }
 
-static bool ppir_lower_ddxy(ppir_block *block, ppir_node *node)
-{
-   assert(node->type == ppir_node_type_alu);
-   ppir_alu_node *alu = ppir_node_to_alu(node);
-
-   alu->src[1] = alu->src[0];
-   if (node->op == ppir_op_ddx)
-      alu->src[1].negate = !alu->src[1].negate;
-   else if (node->op == ppir_op_ddy)
-      alu->src[0].negate = !alu->src[0].negate;
-   else
-      assert(0);
-
-   alu->num_src = 2;
-
-   return true;
-}
-
 static bool ppir_lower_texture(ppir_block *block, ppir_node *node)
 {
    ppir_dest *dest = ppir_node_get_dest(node);
@@ -424,8 +406,6 @@ static bool (*ppir_lower_funcs[ppir_op_num])(ppir_block *, ppir_node *) = {
    [ppir_op_abs] = ppir_lower_abs,
    [ppir_op_neg] = ppir_lower_neg,
    [ppir_op_const] = ppir_lower_const,
-   [ppir_op_ddx] = ppir_lower_ddxy,
-   [ppir_op_ddy] = ppir_lower_ddxy,
    [ppir_op_lt] = ppir_lower_swap_args,
    [ppir_op_le] = ppir_lower_swap_args,
    [ppir_op_load_texture] = ppir_lower_texture,
diff --git a/src/gallium/drivers/lima/lima_job.c b/src/gallium/drivers/lima/lima_job.c
index 3ec53db2d2a..340dd447b86 100644
--- a/src/gallium/drivers/lima/lima_job.c
+++ b/src/gallium/drivers/lima/lima_job.c
@@ -57,6 +57,8 @@ lima_get_fb_info(struct lima_job *job)
    fb->width = ctx->framebuffer.base.width;
    fb->height = ctx->framebuffer.base.height;
 
+   fb->flip_y = ctx->framebuffer.base.flip_y;
+
    int width = align(fb->width, 16) >> 4;
    int height = align(fb->height, 16) >> 4;
 
@@ -875,11 +877,26 @@ lima_pack_pp_frame_reg(struct lima_job *job, uint32_t *frame_reg,
    frame->fragment_stack_size = job->pp_max_stack_size << 16 | job->pp_max_stack_size;
 
    /* related with MSAA and different value when r4p0/r7p0 */
-   frame->supersampled_height = fb->height * 2 - 1;
-   frame->scale = 0xE0C;
+   if (fb->flip_y)
+      frame->supersampled_height = fb->height * 2 - 1;
+   else
+      frame->supersampled_height = 1;
+
+   frame->scale = 0x00C;
+   if (fb->flip_y) {
+      /* 11: flip derivative y
+       * 10: flip fragcoord y
+       *  9: flip dithering */
+      frame->scale |= (1<<11) | (1<<10) | (1<<9);
+   }
 
    frame->dubya = 0x77;
-   frame->onscreen = 1;
+
+   if (fb->flip_y)
+      frame->onscreen = 1;
+   else
+      frame->onscreen = 0;
+
    frame->blocking = (fb->shift_min << 28) | (fb->shift_h << 16) | fb->shift_w;
 
    /* Set default layout to 8888 */
diff --git a/src/gallium/drivers/lima/lima_job.h b/src/gallium/drivers/lima/lima_job.h
index a43b8be1c10..49220f46ae4 100644
--- a/src/gallium/drivers/lima/lima_job.h
+++ b/src/gallium/drivers/lima/lima_job.h
@@ -57,6 +57,7 @@ struct lima_job_fb_info {
    int shift_w, shift_h;
    int block_w, block_h;
    int shift_min;
+   int flip_y;
 };
 
 struct lima_job {
diff --git a/src/gallium/drivers/lima/lima_screen.c b/src/gallium/drivers/lima/lima_screen.c
index 6215b2bc7e9..a92aa48ace0 100644
--- a/src/gallium/drivers/lima/lima_screen.c
+++ b/src/gallium/drivers/lima/lima_screen.c
@@ -119,6 +119,9 @@ lima_screen_get_param(struct pipe_screen *pscreen, enum pipe_cap param)
    case PIPE_CAP_FS_COORD_PIXEL_CENTER_HALF_INTEGER:
       return 1;
 
+   case PIPE_CAP_LOWER_WPOS_YTRANSFORM:
+      return 0;
+
    case PIPE_CAP_FS_POSITION_IS_SYSVAL:
    case PIPE_CAP_FS_POINT_IS_SYSVAL:
    case PIPE_CAP_FS_FACE_IS_INTEGER_SYSVAL:
-- 
GitLab

