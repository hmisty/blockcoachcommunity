pragma solidity >=0.4.22 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }
        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

contract chaired {
    // chairman of parliament
    address public chairman;

    constructor() public {
        chairman = msg.sender;
    }

    modifier onlyChairman {
        require(msg.sender == chairman);
        _;
    }

    function changeChairman(address newChairman) onlyChairman public {
        chairman = newChairman;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/**
 * @title Parliament
 */
contract BCParliament is chaired {
    using SafeMath for uint;
    
    // public vars of parliament members
    ERC20Interface public token;
    
    // chairman can validate/invalidate membership
    mapping(address => bool) public membership;
    // parliament members must deposit BCS as stake to this contract for voting weights
    mapping(address => uint256) public memberstake;
    
    // public vars of decisions
    uint256 public budgetApproved;
    address public presidentApproved;
    
    // public vars for voting
    uint256 public newBudgetProposal;
    uint256 public stakeForNewBudgetProposal;
    uint256 public stakeAgainstNewBudgetProposal;
    uint256 public roundOnBudget; //which round of voting on budget
    mapping(address => uint) public memberBudgetVoteRound;

    address public newPresidentProposal;
    uint256 public stakeForNewPresidentProposal;
    uint256 public stakeAgainstNewPresidentProposal;
    uint256 public roundOnPresident; //which round of voting on president
    mapping(address => uint) public memberPresidentVoteRound;

    /*
     * specify which DAO this parliament would work with.
     */
    constructor (address _token) public {
        token = ERC20Interface(_token);
    }
    
    /* check if there is still enough budget approved by the parliament.
     * this function should be idempotent.
     */
    function isBudgetApproved(uint256 amount) public view returns (bool) {
        return (budgetApproved >= amount);
    }
    
    /* consume the approved budget, i.e. deduct the number.
     * CANNOT be internal. how to limit the consumer to token president?
     */
    function consumeBudget(uint256 amount) public {
        require(msg.sender == address(token));
        require(budgetApproved >= amount);
        budgetApproved = budgetApproved.sub(amount);
    }
    
    /* check if the specified new president has been approved by the parliament.
     * this function should be idempotent.
     */
    function isPresidentApproved(address newPresident) public view returns (bool) {
        require(newPresident != address(0));
        return (presidentApproved == newPresident);
    }
    
    /* chairman validate membership
     */
    function validateMembership(address member) public {
        require(member != address(0));
        membership[member] = true;
    }
    
    function multiValidateMembership(address[] memory members) public {
        for (uint8 i = 0; i < members.length; i++) {
            if (members[i] != address(0)) {
                membership[members[i]] = true;
            }
        }
    }
    
    /* chairman invalidate membership
     */
    function invalidateMembership(address member) public {
        require(member != address(0));
        membership[member] = false;
    }
    
    function multiInvalidateMembership(address[] memory members) public {
        for (uint8 i = 0; i < members.length; i++) {
            if (members[i] != address(0)) {
                membership[members[i]] = false;
            }
        }
    }
    
    /* common functions to clear votes and go to next round
     */
    function clearVoteOnNewBudgetProposal() private {
        stakeForNewBudgetProposal = 0;
        stakeAgainstNewBudgetProposal = 0;
        roundOnBudget = roundOnBudget.add(1); // next round
    }

    function clearVoteOnNewPresidentProposal() private {
        stakeForNewPresidentProposal = 0;
        stakeAgainstNewPresidentProposal = 0;
        roundOnPresident = roundOnPresident.add(1); // next round
    }
 
    /* chariman set proposals to be voted
     */
    function setNewBudgetProposal(uint256 _budget) public {
        require(_budget > 0);
        newBudgetProposal = _budget;
        clearVoteOnNewBudgetProposal();
    }
    
    function setNewPresidentProposal(address _president) public {
        require(_president != address(0));
        newPresidentProposal = _president;
        clearVoteOnNewPresidentProposal();
    }
    
    /* parliament member to deposit BCS as stake for voting weights.
     * MUST call token's approve(parliament address, amount) first,
     * then call deposit to put stake in.
     */
    function deposit(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), amount);
        memberstake[msg.sender] = memberstake[msg.sender].add(amount);
    }
    
    function withdraw(uint256 amount) public {
        require(amount <= memberstake[msg.sender]);
        memberstake[msg.sender] = memberstake[msg.sender].sub(amount);
        token.transfer(msg.sender, amount);
    }
    
    /* parliament members to vote
     */
    function voteForNewBudgetProposal() public {
        require(newBudgetProposal > 0); // valid proposal exists to vote
        
        address member = msg.sender;
        require(membership[member] == true);
        require(memberBudgetVoteRound[member] != roundOnBudget); //not yet voted
        memberBudgetVoteRound[member] = roundOnBudget;
        stakeForNewBudgetProposal = stakeForNewBudgetProposal.add(memberstake[member]);
        
        if (stakeForNewBudgetProposal.mul(2) >= token.balanceOf(address(this))) {
            // >= 50% stakes supports
            budgetApproved = budgetApproved.add(newBudgetProposal);
            newBudgetProposal = 0;
            clearVoteOnNewBudgetProposal();
        }
    }
    
    function voteAgainstNewBudgetProposal() public {
        require(newBudgetProposal > 0); // valid proposal exists to vote
        
        address member = msg.sender;
        require(membership[member] == true);
        require(memberBudgetVoteRound[member] != roundOnBudget); //not yet voted
        memberBudgetVoteRound[member] = roundOnBudget;
        stakeAgainstNewBudgetProposal = stakeAgainstNewBudgetProposal.add(memberstake[member]);
        
        if (stakeAgainstNewBudgetProposal.mul(2) >= token.balanceOf(address(this))) {
            // >= 50% stakes against. failed to approve the budget proposal
            newBudgetProposal = 0;
            clearVoteOnNewBudgetProposal();
        }
    }

    function voteForNewPresidentProposal() public {
        require(newPresidentProposal != address(0)); // valid proposal exists to vote
        
        address member = msg.sender;
        require(membership[member] == true);
        require(memberPresidentVoteRound[member] != roundOnPresident); //not yet voted
        memberPresidentVoteRound[member] = roundOnPresident;
        stakeForNewPresidentProposal = stakeForNewPresidentProposal.add(memberstake[member]);
        
        if (stakeForNewPresidentProposal.mul(2) >= token.balanceOf(address(this))) {
            // >= 50% stakes supports
            presidentApproved = newPresidentProposal;
            newPresidentProposal = address(0);
            clearVoteOnNewPresidentProposal();
        }        
    }
    
    function voteAgainstNewPresidentProposal() public {
        require(newPresidentProposal != address(0)); // valid proposal exists to vote
        
        address member = msg.sender;
        require(membership[member] == true);
        require(memberPresidentVoteRound[member] != roundOnPresident); //not yet voted
        memberPresidentVoteRound[member] = roundOnPresident;
        stakeForNewPresidentProposal = stakeForNewPresidentProposal.add(memberstake[member]);
        
        if (stakeForNewPresidentProposal.mul(2) >= token.balanceOf(address(this))) {
            // >= 50% stakes against. failed to approve the president proposal
            newPresidentProposal = address(0);
            clearVoteOnNewPresidentProposal();
        }
    }
}
