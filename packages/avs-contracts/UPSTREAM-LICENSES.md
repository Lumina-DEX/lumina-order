# Upstream licensing

The AVS example in this directory is adapted from [Layr-Labs/hello-world-avs](https://github.com/Layr-Labs/hello-world-avs/tree/a9e440507308b9360709f1b5f88481a9eb4e949f), revision dated April 16, 2025, preceding the July 23, 2025 import into this repository.

This upstream-derived code is excluded from the repository's Apache-2.0 relicensing. Its existing file-level declarations and copyright attribution remain unchanged. The upstream repository has an MIT license, reproduced in LICENSE.upstream, while individual Solidity files declare BUSL-1.1, MIT, or UNLICENSED. This change preserves those declarations without resolving or replacing the upstream's differing terms. UNLICENSED is not an open-source license grant.

| Local source | Existing declaration | Upstream source / comparison |
| --- | --- | --- |
| `contracts/mocks/MockStrategy.sol` | `BUSL-1.1` | [Identical](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/mocks/MockStrategy.sol) |
| `contracts/script/DeployEigenLayerCore.s.sol` | `BUSL-1.1` | [Identical](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/script/DeployEigenLayerCore.s.sol) |
| `contracts/script/SetupDistributions.s.sol` | `UNLICENSED` | [Adapted (names/paths/casing)](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/script/SetupDistributions.s.sol) |
| `contracts/script/SilvanaDeployer.s.sol` | `UNLICENSED` | [Adapted (names/paths/casing)](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/script/HelloWorldDeployer.s.sol) |
| `contracts/script/utils/CoreDeploymentParsingLib.sol` | `UNLICENSED` | [Identical](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/script/utils/CoreDeploymentParsingLib.sol) |
| `contracts/script/utils/SetupDistributionsLib.sol` | `UNLICENSED` | [Adapted (names/paths/casing)](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/script/utils/SetupDistributionsLib.sol) |
| `contracts/script/utils/SilvanaDeploymentLib.sol` | `UNLICENSED` | [Adapted (names/paths/casing and configuration)](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/script/utils/HelloWorldDeploymentLib.sol) |
| `contracts/script/utils/UpgradeableProxyLib.sol` | `UNLICENSED` | [Identical](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/script/utils/UpgradeableProxyLib.sol) |
| `contracts/src/ISilvanaServiceManager.sol` | `UNLICENSED` | [Adapted (names/paths/casing)](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/src/IHelloWorldServiceManager.sol) |
| `contracts/src/SilvanaServiceManager.sol` | `UNLICENSED` | [Adapted (names/paths/casing)](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/src/HelloWorldServiceManager.sol) |
| `contracts/test/CoreDeploymentLib.t.sol` | `UNLICENSED` | [Identical](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/test/CoreDeploymentLib.t.sol) |
| `contracts/test/ERC20Mock.sol` | `MIT` | [Identical](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/test/ERC20Mock.sol) |
| `contracts/test/SetupPaymentsLib.t.sol` | `UNLICENSED` | [Adapted (names/paths/casing)](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/test/SetupPaymentsLib.t.sol) |
| `contracts/test/SilvanaServiceManager.t.sol` | `UNLICENSED` | [Adapted (names/paths/casing)](https://github.com/Layr-Labs/hello-world-avs/blob/a9e440507308b9360709f1b5f88481a9eb4e949f/contracts/test/HelloWorldServiceManager.t.sol) |

Six Solidity files are byte-for-byte identical to upstream. The remaining eight are adaptations, primarily renaming HelloWorld to Silvana. SilvanaDeploymentLib also changes the constructor configuration value from 4 to 50. These source files are unchanged by this license update.
