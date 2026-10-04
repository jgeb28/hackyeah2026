// Locks the two LAY A questions that are baked into the on-device `.ms`
// (root AGENTS §11): the `deception` gate and the 9-option `incident` question.
import { describe, it, expect } from '@ohos/hypium';
import { GuardianSchema } from '../main/ets/domain/model/GuardianSchema';

/** Incident ids in `rawfile/kb/en/incidents.json` file order = graph option order. */
const INCIDENT_IDS: string[] = [
  'family-emergency-money',
  'misinfo-breaking-event',
  'bank-authority-impersonation',
  'delivery-fee-smishing',
  'otp-verification-theft',
  'investment-guaranteed-returns',
  'sextortion-blackmail',
  'hate-abuse'
];

export default function guardianContractTest() {
  describe('GuardianLayaContract', () => {
    it('exposes exactly the two baked questions, deception first', 0, () => {
      GuardianSchema.setIncidentChoices(INCIDENT_IDS, INCIDENT_IDS);
      const qs = GuardianSchema.questions();
      expect(qs.length).assertEqual(2);
      expect(qs[0].key).assertEqual('deception');
      expect(qs[0].labels.length).assertEqual(2);
      expect(qs[0].labels[0]).assertEqual('safe');
      expect(qs[0].labels[1]).assertEqual('deceptive');
    });

    it('second question is the 8-id incident choice in KB order', 0, () => {
      GuardianSchema.setIncidentChoices(INCIDENT_IDS, INCIDENT_IDS);
      const qs = GuardianSchema.questions();
      expect(qs[1].key).assertEqual('incident');
      expect(qs[1].labels.length).assertEqual(8);
      expect(GuardianSchema.maxOptions()).assertEqual(8);
      expect(GuardianSchema.indexOf('incident')).assertEqual(1);
      for (let i = 0; i < INCIDENT_IDS.length; i++) {
        expect(qs[1].labels[i]).assertEqual(INCIDENT_IDS[i]);
      }
    });
  });
}
