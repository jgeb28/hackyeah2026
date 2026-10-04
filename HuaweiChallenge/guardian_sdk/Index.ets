// Guardian SDK — host apps report rendered text via GuardianClient (DESIGN §7.1).
export { GuardianClient, CommonEventEmitter } from './src/main/ets/GuardianClient';
export type { ReportEmitter } from './src/main/ets/GuardianClient';
export {
  GUARDIAN_MESSAGE_EVENT,
  GUARDIAN_SDK_VERSION,
  encodeReport,
  decodeReport
} from './src/main/ets/GuardianProtocol';
export type { GuardianReport } from './src/main/ets/GuardianProtocol';
