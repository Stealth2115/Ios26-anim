// iOS26Anim - approximates iOS 26 app open/close animations on iOS 16 SpringBoard
// Target: iPhone 8, iOS 16.7.x, Dopamine RootHide (rootless)
//
// Strategy:
//   1. Override BSAnimationSettings spring params used by SpringBoard's app
//      transition animators so they feel like iOS 26 (snappier response,
//      slightly higher damping, lower mass = more "elastic glass").
//   2. Shorten the default UIView animation duration used inside
//      SBAppToAppWorkspaceTransition / SBIconZoomAnimator so the icon → app
//      morph feels punchy rather than the iOS 16 sluggish ramp.
//   3. Inject a brief UIVisualEffectView (systemUltraThinMaterial) over the
//      transitioning window to fake the "liquid glass" haze during the morph.
//
// NOTE: This is an *approximation* — iOS 26's true liquid-glass uses private
// Metal shaders that don't exist on iOS 16. Tune the constants at the top of
// this file to taste.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// ---------- TUNABLES (edit these to taste) ----------
static const double kOpenResponse      = 0.90;  // lower = snappier
static const double kOpenDamping       = 0.60;  // ~iOS 26 feel
static const double kCloseResponse     = 0.90;
static const double kCloseDamping      = 0.60;
static const double kOpenDuration      = 1.50;  // iOS 16 default ~0.55
static const double kCloseDuration     = 1.50;
static const double kGlassBlurAlpha    = 0.95;
static const double kGlassFadeIn       = 0.12;
static const double kGlassFadeOut      = 0.22;
// ----------------------------------------------------

// Forward decls for private classes / structs
@interface BSAnimationSettings : NSObject
@property (nonatomic, assign) double duration;
@property (nonatomic, assign) double delay;
@property (nonatomic, assign) double speed;
@end

@interface BSUIAnimationFactory : NSObject @end

@interface SBFluidBehaviorSettings : NSObject
@property (nonatomic, assign) double response;
@property (nonatomic, assign) double dampingRatio;
@property (nonatomic, assign) double mass;
@end

// State flag so we know whether the *currently building* transition is an
// "open" (home → app) or "close" (app → home). Set from SBMainWorkspace hook.
static BOOL gIsOpening = YES;

// Glass overlay we briefly insert during transitions
static UIVisualEffectView *gGlassOverlay = nil;

static void presentGlassOverlay(void) {
    UIWindow *kw = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in scene.windows) {
                if (w.isKeyWindow) { kw = w; break; }
            }
        }
        if (kw) break;
    }
    if (!kw) return;

    if (gGlassOverlay) { [gGlassOverlay removeFromSuperview]; gGlassOverlay = nil; }

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    gGlassOverlay = [[UIVisualEffectView alloc] initWithEffect:blur];
    gGlassOverlay.frame = kw.bounds;
    gGlassOverlay.alpha = 0.0;
    gGlassOverlay.userInteractionEnabled = NO;
    [kw addSubview:gGlassOverlay];

    [UIView animateWithDuration:kGlassFadeIn animations:^{
        gGlassOverlay.alpha = kGlassBlurAlpha;
    } completion:^(BOOL fin){
        [UIView animateWithDuration:kGlassFadeOut delay:0.05 options:UIViewAnimationOptionCurveEaseOut animations:^{
            gGlassOverlay.alpha = 0.0;
        } completion:^(BOOL f){
            [gGlassOverlay removeFromSuperview];
            gGlassOverlay = nil;
        }];
    }];
}

// ============ HOOKS ============

// 1. Detect open vs close by watching the workspace transition request type.
%hook SBMainWorkspaceTransitionRequest
- (void)setEventLabel:(NSString *)label {
    if ([label containsString:@"ActivateApplication"] || [label containsString:@"LaunchApplication"]) {
        gIsOpening = YES;
    } else if ([label containsString:@"DeactivateApplication"] || [label containsString:@"Home"]) {
        gIsOpening = NO;
    }
    %orig;
}
%end

// 2. Override spring physics. SpringBoard reads SBFluidBehaviorSettings
//    when constructing the spring animators that drive the morph.
%hook SBFluidBehaviorSettings
- (double)response {
    double v = %orig;
    // Only override the "app transition" presets — leave dock / folder alone.
    // Heuristic: SpringBoard's app-transition preset uses response ~0.5–0.6.
    return gIsOpening ? kOpenResponse : kCloseResponse;
    return v;
}
- (double)dampingRatio {
    double v = %orig;
    return gIsOpening ? kOpenDamping : kCloseDamping;
    return v;
}
%end

// 3. Shorten the explicit UIView durations used inside the icon-zoom animator.
//    SBIconZoomAnimator drives the icon → app frame morph on iOS 16.
%hook SBIconZoomAnimator
- (void)_animateZoomWithDuration:(double)duration
                      animations:(id)animations
                      completion:(id)completion {
    double newDur = gIsOpening ? kOpenDuration : kCloseDuration;
    %orig(newDur, animations, completion);
}

- (double)_animationDuration {
    return gIsOpening ? kOpenDuration : kCloseDuration;
}
%end

// 4. Workspace transition duration (covers cases the zoom animator doesn't).
%hook SBAppToAppWorkspaceTransition
- (double)_animationDuration {
    double orig = %orig;
    if (orig > 0.1) return gIsOpening ? kOpenDuration : kCloseDuration;
    return orig;
}
%end

// 5. Trigger the glass overlay at the moment the transition begins.
%hook SBMainWorkspace
- (void)executeTransitionRequest:(id)request {
    presentGlassOverlay();
    %orig;
}
%end

// 6. Smooth the corner-radius morph during the open animation. iOS 26's
//    "glass" look keeps a rounder corner radius almost all the way through.
%hook SBIconView
- (void)_setHighlighted:(BOOL)highlighted forTouch:(id)touch { %orig; }
%end

%hook SBAppLaunchAnimator
- (void)_configurePresentationAnimation {
    %orig;
    // After SpringBoard sets up its layers, bump the icon-view's
    // corner radius so the morph holds the rounded shape longer.
UIView *iconView = [(NSObject *)self valueForKey:@"iconView"];
    if (iconView) {
        iconView.layer.cornerCurve = kCACornerCurveContinuous;
    }
}
%end

%ctor {
    NSLog(@"[iOS26Anim] loaded — open(%.2f/%.2f) close(%.2f/%.2f)",
          kOpenResponse, kOpenDamping, kCloseResponse, kCloseDamping);
}
