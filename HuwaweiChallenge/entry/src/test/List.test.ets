import localUnitTest from './LocalUnit.test';
import guardianContractTest from './GuardianContract.test';

export default function testsuite() {
  localUnitTest();
  guardianContractTest();
}