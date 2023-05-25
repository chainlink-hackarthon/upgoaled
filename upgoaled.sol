// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GoalTracker is Ownable {
    // User struct to store user information
    struct User {
        address userAddress; // Wallet address of the user
        string name; // Username
        uint[] goals; // List of goal IDs associated with the user
    }
    // Goal struct to store goal information
    struct Goal {
        string title; // Title of the goal
        string description; // Description of the goal
        uint stake; // Amount of stake for the goal
        uint[] participants; // List of user IDs participating in the goal
        bool completed; // Whether the goal is completed
    }
    // GoalPool struct to store goal pool information
    struct GoalPool {
        string name; // Name of the goal pool
        uint[] goals; // List of goal IDs in the goal pool
    }

    uint public userCount; // Counter for the total number of users
    uint public goalCount; // Counter for the total number of goals
    uint public goalPoolCount; // Counter for the total number of goal pools

    // Maximum number of goal pools allowed
    uint public constant MAX_GOAL_POOLS = 2;
    uint public constant MAX_GOALS_PER_POOL = 3;

    // Mappings to store user, goal, and goal pool data
    mapping(uint => User) public users;
    mapping(uint => Goal) public goals;
    mapping(uint => GoalPool) public goalPools;
    mapping(uint => mapping(uint => uint)) public stakedAmounts;
    mapping(uint => uint) public totalFailedStakes;
    mapping(uint => mapping(uint => bool)) public rewardsClaimed;
    mapping(address => bool) public addressUsed;
    mapping(uint => mapping(uint => bool)) public userParticipatedInGoal;

    // Events
    event UserCreated(uint indexed userId, string name, address userAddress);
    event GoalPoolCreated(uint indexed goalPoolId, string name);
    event GoalCreated(uint indexed goalId, string title, uint stake, uint goalPoolId);
    event GoalFailed(uint indexed userId, uint indexed goalId);
    event RewardsClaimed(uint indexed userId, uint indexed goalId);

    // Function to create a new user with a username and wallet address
    function createUser(string memory _name, address _userAddress) public {
        require(!addressUsed[_userAddress], "User can only create an account once");

        userCount++;
        users[userCount] = User(_userAddress, _name, new uint[](0));

        addressUsed[_userAddress] = true;
    }
    // Function to create a new goal pool with a name
    function createGoalPool(string memory _name) public {
        // Check if the number of goal pools has reached the limit
        require(goalPoolCount < MAX_GOAL_POOLS, "Maximum number of goal pools reached");

        goalPoolCount++;
        goalPools[goalPoolCount] = GoalPool(_name, new uint[](0));
        emit GoalPoolCreated(goalPoolCount, _name);
    }

    // Function to associate a goal with a user
    function addGoalToUser(uint _userId, uint _goalId) internal {
        users[_userId].goals.push(_goalId);
    }
   
    // Function to create a goal, stake tokens, and add it to the goal pool
    function joinGoal(string memory _title, uint _stake, address _token, Address, uint _goalPoolId, uint _userId) public {
        // Check if the number of goals in the pool has reached the limit
        require(goalPools[_goalPoolId].goals.length < MAX_GOALS_PER_POOL, "Maximum number of goals per pool reached");
        // Create a new goal with the provided title and stake
        goalCount++;
        goals[goalCount] = Goal(_title, "", _stake, new uint[](0), false);

        // Ensure the user approves the contract to transfer tokens on their behalf
        IERC20 token = IERC20(_tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= _stake, "Token allowance not sufficient");

        // Require that the user must stake tokens to create the goal
        require(_stake > 0, "User must stake tokens to create the goal");

        // Transfer tokens from the user to the contract
        token.transferFrom(msg.sender, address(this), _stake);

        // Add the goal to the specified goal pool
        goalPools[_goalPoolId].goals.push(goalCount);
        // Add the goal to the user
        addGoalToUser(_userId, goalCount);

        // Record user's participation in the goal
        userParticipatedInGoal[_userId][goalCount] = true;

        emit GoalCreated(goalCount, _title, _stake, _goalPoolId);
    }
    
    // Function to mark a user as failed for a goal
    function failGoal(uint _userId, uint _goalId) public onlyOwner {
        // Ensure the user has participated in the goal
        require(userParticipatedInGoal[_userId][_goalId], "User must have participated in the goal");

        // Ensure the goal is not already completed
        require(!goals[_goalId].completed, "Goal must not be completed");

        // Increase the total failed stakes for the goal
        uint stakedAmount = stakedAmounts[_userId][_goalId];
        totalFailedStakes[_goalId] += stakedAmount;

        // Reset the staked amount for the user and goal
        stakedAmounts[_userId][_goalId] = 0;

        emit GoalFailed(_userId, _goalId);
    }

    // Function to allow a user to claim rewards after completing a goal
    function claimRewards(uint _userId, uint _goalId, address _tokenAddress) public {
        // Ensure the goal is completed
        require(goals[_goalId].completed, "Goal must be completed");

        // Ensure the user has participated in the goal
        require(userParticipatedInGoal[_userId][_goalId], "User must have participated in the goal");

        // Ensure the user has not already claimed their rewards
        require(!rewardsClaimed[_userId][_goalId], "User has already claimed rewards");
         // Ensure the user has staked tokens in the goal
        uint stakedAmount = stakedAmounts[_userId][_goalId];
        require(stakedAmount > 0, "User must have staked tokens in the goal");

        // Transfer the staked tokens back to the user
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, stakedAmount);

        // Reset the staked amount for the user and goal
        stakedAmounts[_userId][_goalId] = 0;

        // Ensure there is at least one completed goal
        uint completedGoalsCount = 0;
        for (uint i = 1; i <= goalCount; i++) {
            if (goals[i].completed) {
                completedGoalsCount++;
            }
        }
        require(completedGoalsCount > 0, "There must be at least one completed goal");

        // Calculate the user's share of the failed stakes
        uint userShare = totalFailedStakes[_goalId] / completedGoalsCount;

        // Transfer the user's share of the failed stakes
        token.transfer(msg.sender, userShare);

        // Mark the rewards as claimed for the user and goal
        rewardsClaimed[_userId][_goalId] = true;

        emit RewardsClaimed(_userId, _goalId);
    }

    // Function to set a goal as completed
    function passGoal(uint _goalId) public onlyOwner {
        // Ensure the goal is not already completed
        require(!goals[_goalId].completed, "Goal is already completed");

        // Set the goal as completed
        goals[_goalId].completed = true;
    }
}
