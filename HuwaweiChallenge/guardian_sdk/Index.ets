/**
 * Guardian SDK — the in-app trigger contract for the Guardian safety copilot.
 *
 * A host app links this HAR and calls `GuardianClient.report(...)` whenever it
 * renders message text. The report travels as a common event to the Guardian
 * engine, which classifies it on-device (DESIGN.md §7.1, Phase 1).
 *
 * Platform-free pieces (`GuardianProtocol`) are unit-tested off-device.
 */
export { GuardianClient, CommonEventEmitter } from './src/main/ets/GuardianClient';
export type { ReportEmitter } from './src/main/ets/GuardianClient';
export {
  GUARDIAN_MESSAGE_EVENT,
  GUARDIAN_SDK_VERSION,
  encodeReport,
  decodeReport
} from './src/main/ets/GuardianProtocol';
export type { GuardianReport } from './src/main/ets/GuardianProtocol';
