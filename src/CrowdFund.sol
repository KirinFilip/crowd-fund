// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IERC20.sol";

contract CrowdFund {
    struct Campaign {
        address creator;
        uint256 goal;
        uint32 startAt;
        uint32 endAt;
        bool isClaimed;
    }

    /// @notice Token used in a campaign
    IERC20 public immutable token;
    /// @notice Unique id for each campaign
    uint256 public count;
    /// @notice id of a campaign to the campaign struct
    mapping(uint256 => Campaign) public campaigns;
    /// @notice amount of tokens a user has pledged to a specific campaign
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;

    /// @notice Initialize the token for the crowd fund
    /// @param _token specific token we want to crowd fund
    constructor(address _token) {
        token = IERC20(_token);
    }

    /// @notice Launch the crowd fund campaign
    /// @dev Explain to a developer any extra details
    /// @param _goalAmount the amount of tokens we want to raise
    /// @param _startAt the start time of the campaign
    /// @param _endAt the end time when the campaign will end
    function launchCampaign(
        uint256 _goalAmount,
        uint32 _startAt,
        uint32 _endAt
    ) external {}

    /// @notice Cancel the campaign if it has not started
    /// @dev Only available to the campaign creator
    /// @param _id id of a campaign
    function cancelCampaign(uint256 _id) external {}

    /// @notice Pledge an amonut of tokens to a specific campaign
    /// @dev Tokens are transferred to this contract
    /// @param _id id of a campaign
    /// @param _amount the amount of tokens a user wants to pledge
    function pledge(uint256 _id, uint256 _amount) external {}

    /// @notice Unpledge an amount of tokens from a specific campaign
    /// @dev Tokens are transferred to this contract
    /// @param _id id of a campaign
    /// @param _amount the amount of tokens a user wants to unpledge
    function unpledge(uint256 _id, uint256 _amount) external {}

    /// @notice Claim all the pledged tokens
    /// @dev Callable only if the `_goalAmount` is met
    /// @param _id id of a campaign
    function claim(uint256 _id) external {}

    /// @notice Refund the amount of tokens pledged by a user
    /// @dev Callable if the `_goalAmount` was not met
    /// @param _id id of a campaign
    function refund(uint256 _id) external {}
}
