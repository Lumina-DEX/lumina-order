// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {SilvanaDeploymentLib} from "./utils/SilvanaDeploymentLib.sol";
import {CoreDeployLib, CoreDeploymentParsingLib} from "./utils/CoreDeploymentParsingLib.sol";
import {SetupDistributionsLib} from "./utils/SetupDistributionsLib.sol";
import {IRewardsCoordinator} from "@eigenlayer/contracts/interfaces/IRewardsCoordinator.sol";
import {RewardsCoordinator} from "@eigenlayer/contracts/core/RewardsCoordinator.sol";
import {IStrategy} from "@eigenlayer/contracts/interfaces/IStrategy.sol";
import {ERC20Mock} from "../test/ERC20Mock.sol";

import "forge-std/Test.sol";

contract SetupDistributions is Script, Test {
    struct PaymentInfo {
        address recipient;
        uint32 numPayments;
        uint32 amountPerPayment;
        uint32 duration;
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint256 indexToProve;
    }

    address private deployer;
    CoreDeployLib.DeploymentData coreDeployment;
    CoreDeployLib.DeploymentConfigData coreConfig;

    SilvanaDeploymentLib.DeploymentData silvanaDeployment;
    SilvanaDeploymentLib.DeploymentConfigData silvanaConfig;

    RewardsCoordinator rewardsCoordinator;
    string internal constant paymentInfofilePath = "test/mockData/scratch/payment_info.json";
    string internal constant filePath = "test/mockData/scratch/payments.json";

    uint32 constant CALCULATION_INTERVAL_SECONDS = 1 days;
    uint256 constant NUM_TOKEN_EARNINGS = 1;
    //duration MUST be a multiple of CALCULATION_INTERVAL_SECONDS .
    //https://github.com/Layr-Labs/eigenlayer-contracts/blob/865e723a6b5c634cf45cce1817dec0ea95f0e03b/src/contracts/core/RewardsCoordinator.sol#L439
    uint32 constant DURATION = 172_800;
    uint32 constant REWARDS_END_TIMESTAMP_GAP = 1 days;
    uint256 constant NUM_EARNERS = 8;

    uint32 numPayments = 8;
    uint32 indexToProve = 0;
    uint32 amountPerPayment = 100;

    address recipient = address(1);
    IRewardsCoordinator.EarnerTreeMerkleLeaf[] public earnerLeaves;
    address[] public earners;
    uint32 startTimestamp;
    uint32 endTimestamp;
    uint256 cumumlativePaymentMultiplier;
    address nonceSender = 0x998abeb3E57409262aE5b751f60747921B33613E;

    address operator1 = address(1);
    address operator2 = address(2);

    function setUp() public {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        vm.label(deployer, "Deployer");

        coreDeployment =
            CoreDeploymentParsingLib.readDeploymentJson("deployments/core/", block.chainid);
        coreConfig =
            CoreDeploymentParsingLib.readDeploymentConfigValues("config/core/", block.chainid);
        silvanaDeployment =
            SilvanaDeploymentLib.readDeploymentJson("deployments/hello-world/", block.chainid);
        silvanaConfig =
            SilvanaDeploymentLib.readDeploymentConfigValues("config/hello-world/", block.chainid);

        rewardsCoordinator = RewardsCoordinator(coreDeployment.rewardsCoordinator);

        // TODO: Get the filePath from config
    }

    function run() external {
        vm.startBroadcast(silvanaConfig.rewardsInitiatorKey);

        // Go back 4 days
        uint256 targetStartTimestamp = block.timestamp - 4 days;
        // Start Timestamp must be a multiple of CALCULATION_INTERVAL_SECONDS
        uint32 diff = (uint32(targetStartTimestamp) % CALCULATION_INTERVAL_SECONDS);
        startTimestamp = uint32(targetStartTimestamp) - diff;

        endTimestamp = uint32(block.timestamp) - REWARDS_END_TIMESTAMP_GAP;
        emit log_named_uint("startTimestamp", startTimestamp);
        emit log_named_uint("endTimestamp", endTimestamp);
        emit log_named_uint("block.timestamp", block.timestamp);
        emit log_named_uint("MAX_RETROACTIVE_LENGTH", rewardsCoordinator.MAX_RETROACTIVE_LENGTH());
        if (endTimestamp > block.timestamp) {
            revert("RewardsEndTimestampNotElapsed.  Please wait to generate new payments.");
        }

        // sets a multiplier based on block number such that cumulativeEarnings increase accordingly for multiple runs of this script in the same session
        uint256 nonce = rewardsCoordinator.getDistributionRootsLength();
        amountPerPayment = uint32(amountPerPayment * (nonce + 1));

        createAVSRewardsSubmissions(numPayments, amountPerPayment, startTimestamp);
        vm.stopBroadcast();
        vm.startBroadcast(deployer);
        earners = _getEarners(deployer);
        submitPaymentRoot(earners, endTimestamp, numPayments, amountPerPayment);
        vm.stopBroadcast();
    }

    function runOperatorDirected() external {
        vm.startBroadcast(silvanaConfig.rewardsInitiatorKey);

        // Go back 4 days
        uint256 targetStartTimestamp = block.timestamp - 4 days;
        // Start Timestamp must be a multiple of CALCULATION_INTERVAL_SECONDS
        uint32 diff = (uint32(targetStartTimestamp) % CALCULATION_INTERVAL_SECONDS);
        startTimestamp = uint32(targetStartTimestamp) - diff;

        endTimestamp = uint32(block.timestamp) - REWARDS_END_TIMESTAMP_GAP;
        emit log_named_uint("startTimestamp", startTimestamp);
        emit log_named_uint("endTimestamp", endTimestamp);
        emit log_named_uint("block.timestamp", block.timestamp);
        emit log_named_uint("MAX_RETROACTIVE_LENGTH", rewardsCoordinator.MAX_RETROACTIVE_LENGTH());
        if (endTimestamp > block.timestamp) {
            revert("RewardsEndTimestampNotElapsed.  Please wait to generate new payments.");
        }

        // sets a multiplier based on block number such that cumulativeEarnings increase accordingly for multiple runs of this script in the same session
        uint256 nonce = rewardsCoordinator.getDistributionRootsLength();
        amountPerPayment = uint32(amountPerPayment * (nonce + 1));

        createOperatorDirectedAVSRewardsSubmissions(
            numPayments, amountPerPayment, startTimestamp, DURATION
        );
        vm.stopBroadcast();
        vm.startBroadcast(deployer);
        earners = _getEarners(deployer);
        submitPaymentRoot(earners, endTimestamp, numPayments, amountPerPayment);
        vm.stopBroadcast();
    }

    function executeProcessClaim() public {
        uint256 nonce = rewardsCoordinator.getDistributionRootsLength();
        amountPerPayment = uint32(amountPerPayment * nonce);

        vm.startBroadcast(deployer);
        earnerLeaves =
            _getEarnerLeaves(_getEarners(deployer), amountPerPayment, silvanaDeployment.strategy);
        processClaim(
            filePath, indexToProve, recipient, earnerLeaves[indexToProve], amountPerPayment
        );
        vm.stopBroadcast();
    }

    function createAVSRewardsSubmissions(
        uint256 _numPayments,
        uint256 _amountPerPayment,
        uint32 _startTimestamp
    ) public {
        ERC20Mock(silvanaDeployment.token).mint(
            silvanaConfig.rewardsInitiator, _amountPerPayment * _numPayments
        );
        ERC20Mock(silvanaDeployment.token).increaseAllowance(
            silvanaDeployment.silvanaServiceManager, _amountPerPayment * _numPayments
        );
        uint32 duration = rewardsCoordinator.MAX_REWARDS_DURATION();
        SetupDistributionsLib.createAVSRewardsSubmissions(
            silvanaDeployment.silvanaServiceManager,
            silvanaDeployment.strategy,
            _numPayments,
            _amountPerPayment,
            duration,
            _startTimestamp
        );
    }

    function createOperatorDirectedAVSRewardsSubmissions(
        uint256 _numPayments,
        uint256 _amountPerPayment,
        uint32 _startTimestamp,
        uint32 duration
    ) public {
        ERC20Mock(silvanaDeployment.token).mint(
            silvanaConfig.rewardsInitiator, _amountPerPayment * _numPayments
        );
        ERC20Mock(silvanaDeployment.token).increaseAllowance(
            silvanaDeployment.silvanaServiceManager, _amountPerPayment * _numPayments
        );
        address[] memory operators = new address[](2);
        operators[0] = operator1;
        operators[1] = operator2;

        SetupDistributionsLib.createOperatorDirectedAVSRewardsSubmissions(
            silvanaDeployment.silvanaServiceManager,
            operators,
            silvanaDeployment.strategy,
            _numPayments,
            _amountPerPayment,
            duration,
            _startTimestamp
        );
    }

    function processClaim(
        string memory _filePath,
        uint256 _indexToProve,
        address _recipient,
        IRewardsCoordinator.EarnerTreeMerkleLeaf memory _earnerLeaf,
        uint32 _amountPerPayment
    ) public {
        SetupDistributionsLib.processClaim(
            IRewardsCoordinator(coreDeployment.rewardsCoordinator),
            _filePath,
            _indexToProve,
            _recipient,
            _earnerLeaf,
            NUM_TOKEN_EARNINGS,
            silvanaDeployment.strategy,
            _amountPerPayment
        );
    }

    function submitPaymentRoot(
        address[] memory _earners,
        uint32 _endTimestamp,
        uint32 _numPayments,
        uint32 _amountPerPayment
    ) public {
        emit log_named_uint("cumumlativePaymentMultiplier", cumumlativePaymentMultiplier);
        bytes32[] memory tokenLeaves = SetupDistributionsLib.createTokenLeaves(
            IRewardsCoordinator(coreDeployment.rewardsCoordinator),
            NUM_TOKEN_EARNINGS,
            _amountPerPayment,
            silvanaDeployment.strategy
        );
        IRewardsCoordinator.EarnerTreeMerkleLeaf[] memory _earnerLeaves =
            SetupDistributionsLib.createEarnerLeaves(_earners, tokenLeaves);
        emit log_named_uint("Earner Leaves Length", _earnerLeaves.length);
        emit log_named_uint("numPayments", _numPayments);

        SetupDistributionsLib.submitRoot(
            IRewardsCoordinator(coreDeployment.rewardsCoordinator),
            tokenLeaves,
            _earnerLeaves,
            _endTimestamp,
            _numPayments,
            NUM_TOKEN_EARNINGS,
            filePath
        );
    }

    function _getEarnerLeaves(
        address[] memory _earners,
        uint32 _amountPerPayment,
        address _strategy
    ) internal view returns (IRewardsCoordinator.EarnerTreeMerkleLeaf[] memory) {
        bytes32[] memory tokenLeaves = SetupDistributionsLib.createTokenLeaves(
            IRewardsCoordinator(coreDeployment.rewardsCoordinator),
            NUM_TOKEN_EARNINGS,
            _amountPerPayment,
            _strategy
        );

        IRewardsCoordinator.EarnerTreeMerkleLeaf[] memory _earnerLeaves =
            SetupDistributionsLib.createEarnerLeaves(_earners, tokenLeaves);

        return _earnerLeaves;
    }

    function _getEarners(
        address _deployer
    ) internal pure returns (address[] memory) {
        address[] memory _earners = new address[](NUM_EARNERS);
        for (uint256 i = 0; i < _earners.length; i++) {
            _earners[i] = _deployer;
        }
        return _earners;
    }
}
