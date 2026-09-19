"""Study16I: one full-arm-constrained whole-return hand path.

The previous16H path cleared the ore but exceeded arm speed limits and
exposed the remaining absolute-rest frame singularity. This candidate
uses all four transported original arm frames and one new constrained
translation solve, with unchanged original full-bone angular limits.
"""
import math
from mathutils import Matrix, Quaternion, Vector
import premium_motion as pm
from bisect import bisect_right
from loop_flow_motion import game_progress, CYCLE_SECONDS
from coordinated_body_motion import CoordinatedBodyMotion


class PivotReturnMotion(CoordinatedBodyMotion):
    TRANSLATION_COEFFICIENTS = ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.047164086345319184, -0.017994821920642765, 0.008667686270867768), (0.09359669496894173, -0.05957972126031774, 0.014275585281879513), (0.11900177639328201, -0.07545588267029912, 0.0005131571072577903), (0.16031095611848561, -0.1286301475203089, -0.01026802783220458), (0.19763170894540227, -0.19043825390172592, 0.024930276806675682), (0.2365737125106654, -0.2659117111565486, 0.1249692886621434), (0.2783546368774202, -0.3376358546351473, 0.2179795942485231), (0.3156777270347877, -0.4076613172953839, 0.30410002952373), (0.36714382738942325, -0.4592302521995649, 0.34244411667018176), (0.39897734973278187, -0.5044567023300219, 0.38609259930278744), (0.46904237434632695, -0.49977433445613456, 0.29535508737085686), (0.4427250824572362, -0.41146080026753795, 0.20308624774014686), (0.5818737730175654, -0.38850642163928223, -0.023865625349889435), (0.3457803249011209, -0.17672243798904053, -0.048543514923311465), (0.1974652747868922, -0.12103268187348427, -0.07373980925797018), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0))
    TRANSLATION_FIT_SHA256 = 'f3b1fecd61a4d81c02f118611f8c84e413a39d56e4f4ba157c7cf8ebd1ac8707'
    BODY_COEFFICIENTS = (0.0, 0.0, 0.0, -0.02971134972666569, -0.09106065131911657, -0.1828757421581289, -0.25790941348179064, -0.30367886921547665, -0.33124804243588896, -0.35099648789030685, -0.39381663567381475, -0.4049635225210093, -0.48265527926002305, -0.23943873392641016, -0.2344521375871191, -0.3756847191373195, -0.279508085383339, -0.14950213206886326, 0.0, 0.0, 0.0)
    BODY_FIT_SHA256 = '23b1180f41516807755ac6f035d69ac67011806bb706ce6b4ce7f721f519bfb6'
    ANGLE_DEGREES = 180.
    END_PHASE = 0.392857142857143
    START_SECONDS = 0.35133333333333333
    END_SECONDS = 0.8840000000000001
    DEGREE = 5
    KNOTS = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.06257822277847307, 0.12515644555694613, 0.1877346683354192, 0.25031289111389227, 0.31289111389236535, 0.3754693366708384, 0.4380475594493115, 0.5006257822277845, 0.5632040050062577, 0.6257822277847307, 0.6883604505632037, 0.7509386733416769, 0.8135168961201499, 0.876095118898623, 0.938673341677096, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
    COEFFICIENTS = (0.0, 0.0, 0.0, 0.5854594729596596, 1.2061127578448432, 1.7251463342038895, 1.5328200987152176, 1.538417001402122, 1.383379782891682, 1.306962430578355, 1.2301779649491769, 1.2044597638957928, 1.2887037134783685, 1.43543138958376, 1.910641434453602, 1.665114099704516, 0.9444917352673533, 0.5640542509038114, 0.0, 0.0, 0.0)
    FIT_SHA256 = '388a82adc3376af8848c8cce90ea49353a7a0fb1ad9d82b1d7525e8d6fcf2a6e'

    def __init__(self, *args):
        super().__init__(*args)
        self.pivot_axis = (Vector((0., -.10, .98))-Vector((6., 6., 7.))).normalized()

    @classmethod
    def _angle(cls, phase, coefficients):
        q = phase % 1.
        if cls.END_PHASE <= q <= .625:
            return 0.
        seconds = game_progress(q)*CYCLE_SECONDS
        if q < cls.END_PHASE:
            seconds += CYCLE_SECONDS
        x = (seconds-cls.START_SECONDS)/(cls.END_SECONDS-cls.START_SECONDS)
        if x <= 0. or x >= 1.:
            return 0.
        k = min(len(coefficients)-1, bisect_right(cls.KNOTS, x)-1)
        d = [coefficients[k-cls.DEGREE+j] for j in range(cls.DEGREE+1)]
        for level in range(1, cls.DEGREE+1):
            for j in range(cls.DEGREE, level-1, -1):
                i = k-cls.DEGREE+j
                alpha = (x-cls.KNOTS[i])/(cls.KNOTS[i+cls.DEGREE-level+1]-cls.KNOTS[i])
                d[j] = (1.-alpha)*d[j-1]+alpha*d[j]
        return d[cls.DEGREE]

    @classmethod
    def turn_angle(cls, phase):
        return cls._angle(phase, cls.COEFFICIENTS)

    @classmethod
    def body_yaw(cls, phase):
        return cls._angle(phase, cls.BODY_COEFFICIENTS)

    @classmethod
    def clearance_weight(cls, phase):
        return cls.turn_angle(phase)/math.pi

    @classmethod
    def return_translation(cls, phase):
        return Vector(tuple(cls._angle(phase, tuple(row[j] for row in cls.TRANSLATION_COEFFICIENTS)) for j in range(3)))

    def sample(self, state, phase, speed=340.):
        original = super().sample(state, phase, speed)
        weight = self.clearance_weight(phase) if state == 'mine' else 0.
        if not weight:
            return original
        frame = pm.tool_frame(original['axis'], original['tool_normal']).to_quaternion()
        turn = Quaternion(self.pivot_axis, self.turn_angle(phase))
        joint = original['torso'] @ self.body_joint
        body_turn = (Matrix.Translation(joint)
                     @ Matrix.Rotation(self.body_yaw(phase), 4, 'Z')
                     @ Matrix.Translation(-joint))
        turned = dict(original)
        turned['torso'] = body_turn @ original['torso']
        turned['head'] = body_turn @ original['head']
        result = self._with_tool(turned, original['rear']+self.return_translation(phase), turn@frame)
        for side in ('R', 'L'):
            shoulder, _, wrist = result['arms'][side]
            reference = body_turn @ original['arms'][side][1]
            axis = (wrist-shoulder).normalized()
            pole = reference-shoulder
            projection = (pole-axis*pole.dot(axis)).length
            assert projection > .05, ('Unstable elbow reference', side, projection)
            elbow = pm.solve(shoulder, wrist, reference, .36, .35)
            result['arms'][side] = (shoulder, elbow, wrist)
        old_axis = (original['arms']['R'][2]-original['arms']['R'][1]).normalized()
        radial = original['radials']['R']
        old_radial = radial-old_axis*radial.dot(old_axis)
        assert old_radial.length > .05, ('Unstable original forearm frame', old_radial.length)
        basis = Matrix((old_axis, old_radial.normalized(),
                        old_axis.cross(old_radial.normalized()))).transposed()
        body_rotation = body_turn.to_3x3()
        reference_axis = body_rotation @ old_axis
        new_axis = (result['arms']['R'][2]-result['arms']['R'][1]).normalized()
        denominator = 1.+reference_axis.dot(new_axis)
        assert denominator > .05, ('Antipodal forearm transport', denominator)
        alignment = reference_axis.rotation_difference(new_axis).to_matrix()
        result['right_forearm_basis'] = alignment @ body_rotation @ basis
        result['right_forearm_reference_denominator'] = denominator
        result['right_forearm_original_radial_projection'] = old_radial.length
        old_left_axis = (original['arms']['L'][1]-original['arms']['L'][0]).normalized()
        new_left_axis = (result['arms']['L'][1]-result['arms']['L'][0]).normalized()
        reference_left_axis = body_rotation @ old_left_axis
        left_denominator = 1.+reference_left_axis.dot(new_left_axis)
        assert left_denominator > .05, ('Antipodal left upper-arm transport', left_denominator)
        result['left_upper_original_axis'] = old_left_axis
        result['left_upper_transport'] = reference_left_axis.rotation_difference(new_left_axis).to_matrix() @ body_rotation
        result['left_upper_reference_denominator'] = left_denominator
        result['extra_arm_transports'] = {}
        result['extra_arm_original_axes'] = {}
        result['extra_arm_reference_denominators'] = {}
        for name, side, part in (('upper.R', 'R', 0), ('lower.L', 'L', 1)):
            old_bone_axis = (original['arms'][side][part+1]-original['arms'][side][part]).normalized()
            new_bone_axis = (result['arms'][side][part+1]-result['arms'][side][part]).normalized()
            carried_axis = body_rotation @ old_bone_axis
            den = 1.+carried_axis.dot(new_bone_axis)
            assert den > .05, ('Antipodal additional arm transport', name, den)
            result['extra_arm_transports'][name] = carried_axis.rotation_difference(new_bone_axis).to_matrix() @ body_rotation
            result['extra_arm_original_axes'][name] = old_bone_axis
            result['extra_arm_reference_denominators'][name] = den
        return result

    def selection(self):
        result = super().selection()
        result.update(
            pivot_return_study=True, pivot='Original rear/right grip followed by derived rigid translation',
            rotation_axis=list(self.pivot_axis), angle_degrees=self.ANGLE_DEGREES,
            weight_rule="Positive degree-five B-spline divided by pi",
            curve_fit_sha256=self.FIT_SHA256, curve_knots=list(self.KNOTS),
            curve_coefficients=list(self.COEFFICIENTS), curve_game_seconds=[self.START_SECONDS,self.END_SECONDS],
            unchanged_range='[.392857142857143,.625] complete mining pose',
            changed_ranges='(.625,1) and [0,.392857142857143)',
            unchanged='Hips, legs, feet, body joint and game clock',
            torso_turn_study=True, torso_world_axis=[0,0,1],
            torso_coefficients=list(self.BODY_COEFFICIENTS), torso_fit_sha256=self.BODY_FIT_SHA256,
            both_elbows_reference='Closest point to torso-rotated study15 elbow on the exact new two-link circle',
            protected='Hips, legs, feet, body joint, .392857142857143-.625 complete pose and game clock',
            changed='Rigid tool rotation and translation with derived torso yaw during full return/lift; both arms re-solved',
            translation_coefficients=list(self.TRANSLATION_COEFFICIENTS), translation_fit_sha256=self.TRANSLATION_FIT_SHA256,
            forearm_frame='Original corrected full frame follows torso, then shortest alignment to new forearm axis',
            left_upper_frame='Original native full frame follows torso, then shortest alignment to the new upper-arm axis',
            all_arm_frames='All four arm bones carry their original complete frames with torso and shortest axis alignment',
            translation_objective='Complete wrist-path velocity and acceleration, constrained by unchanged full-bone caps at60/120/1200Hz',
            visual_accepted=False, production_accepted=False)
        return result
