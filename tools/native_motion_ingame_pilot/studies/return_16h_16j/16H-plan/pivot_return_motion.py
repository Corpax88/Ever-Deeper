"""Study16H: continuous whole-return rigid hand translation over16G.

16G re-entered the ore during lift. This candidate keeps its tool/torso
rotations and transported full arm frames, but frees the rear grip to move
along one derived C2 path. Full return/lift and all permitted ore pulse
sizes were included in the fit. Native/visual/game gates remain required.
"""
import math
from mathutils import Matrix, Quaternion, Vector
import premium_motion as pm
from bisect import bisect_right
from loop_flow_motion import game_progress, CYCLE_SECONDS
from coordinated_body_motion import CoordinatedBodyMotion


class PivotReturnMotion(CoordinatedBodyMotion):
    TRANSLATION_COEFFICIENTS = ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.00973687263058649, 0.00263106834346537, -0.012370556923365063), (0.029918463247582, 0.008218772886027854, -0.038147058818980374), (0.034488937230711635, 0.009353851399463924, -0.04385251111644514), (0.013401953216600487, 0.003966497229993092, -0.017376636611721057), (0.007241676782437627, 0.0021259805467317614, -0.009371850835496595), (-0.000520215039647562, 0.0014374651657926654, -0.0009380809424335361), (-0.0003524641670079381, 0.000778198124698251, -0.00043724643830759223), (-0.004410286640361622, 0.002533564881628673, 0.0018284010073479791), (0.006674771981979023, -0.00405697780395916, -0.002541705529522143), (0.017144872334520625, -0.010755837017969037, -0.006189140896596784), (0.09509355581587155, -0.05961226259052172, -0.03437317825465891), (0.18656484037769466, -0.11859267469517862, -0.0657763665490994), (0.4534435119810349, -0.28881658088842727, -0.15928238014398716), (0.4297338080240798, -0.286700538197267, -0.13779560882743364), (0.13982486578058986, -0.09225202944297567, -0.045882361309200564), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0))
    TRANSLATION_FIT_SHA256 = '502456c3b9f367b9616d7933520d7a785d38b7a4ceddb027d1ed4a90c88163b5'
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
            visual_accepted=False, production_accepted=False)
        return result
