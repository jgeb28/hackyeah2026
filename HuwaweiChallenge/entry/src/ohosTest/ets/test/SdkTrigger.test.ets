/**
 * SdkTriggerTest — integration test for the SDK trigger path.
 *
 * Exercises the real contract: a host app encodes a report via the Guardian SDK
 * protocol, the payload is decoded the same way `InAppSdkSource` decodes it, and
 * the decoded text is fed to a real `TriggerEngine`. A fake `TriggerAlertSink`
 * captures the alert without touching the notification subsystem.
 */
import { describe, it, expect } from '@ohos/hypium';
import { encodeReport, decodeReport, GuardianReport } from '@hackyeah/guardian_sdk';
import { TriggerEngine } from '../../../main/ets/trigger/TriggerEngine';
import { ScanPolicy, ScanPolicyConfig } from '../../../main/ets/trigger/ScanPolicy';
import { ScanResult, TriggerSource, Verdict } from '../../../main/ets/trigger/TriggerTypes';
import { TriggerAlertSink } from '../../../main/ets/trigger/IngestSource';

/** Captures alerts so the test never posts a real notification. */
class FakeAlertSink implements TriggerAlertSink {
  alerts: number = 0;
  lastVerdict: string = '';
  lastSource: string = '';

  alert(result: ScanResult, sourceText: string, source: TriggerSource): void {
    this.alerts++;
    this.lastVerdict = result.verdict;
    this.lastSource = source;
  }
}

const FAST_POLICY: ScanPolicyConfig = { dedupeWindowMs: 0, maxScansPerMinute: 1000 };

export default function sdkTriggerTest() {
  describe('GuardianSdkTriggerTest', () => {
    it('decodes an SDK report and scans the text end-to-end', 0, () => {
      const sink: FakeAlertSink = new FakeAlertSink();
      const engine: TriggerEngine = new TriggerEngine(new ScanPolicy(FAST_POLICY), sink);

      // What a host app does: encode a report through the SDK.
      const payload: string = encodeReport({
        bundleName: 'com.hackyeah.mockchat',
        text: "it's me, don't call, send \u20AC4800 urgently",
        messageId: '3'
      });

      // What the Guardian engine does: decode and scan.
      const report: GuardianReport | null = decodeReport(payload);
      expect(report !== null).assertTrue();
      if (report === null) {
        return;
      }
      expect(report.bundleName).assertEqual('com.hackyeah.mockchat');

      const result: ScanResult | null =
        engine.onTextRendered(report.bundleName, report.text, TriggerSource.SDK);
      expect(result !== null).assertTrue();
      if (result === null) {
        return;
      }
      expect(result.verdict).assertEqual(Verdict.CRITICAL);
      expect(sink.alerts).assertEqual(1);
      expect(sink.lastSource).assertEqual(TriggerSource.SDK);
    });

    it('does not alert on benign SDK text', 0, () => {
      const sink: FakeAlertSink = new FakeAlertSink();
      const engine: TriggerEngine = new TriggerEngine(new ScanPolicy(FAST_POLICY), sink);
      const report: GuardianReport | null =
        decodeReport(encodeReport({ bundleName: 'com.hackyeah.mockchat', text: 'lunch at noon?' }));
      expect(report !== null).assertTrue();
      if (report === null) {
        return;
      }
      const result: ScanResult | null =
        engine.onTextRendered(report.bundleName, report.text, TriggerSource.SDK);
      expect(result !== null).assertTrue();
      if (result === null) {
        return;
      }
      expect(result.verdict).assertEqual(Verdict.SAFE);
      expect(sink.alerts).assertEqual(0);
    });
  });
}
