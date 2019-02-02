pragma solidity >=0.4.22 <0.6.0;

/**
 * @title Parliament interface
 */
contract ParliamentInterface {
    /* check if there is still enough budget approved by the parliament.
     * this function should be idempotent.
     */
    function hasBudgetApproved(uint256 amount) public returns (bool);
    
    /* consume the approved budget, i.e. deduct the number.
     */
    function consumeBudget(uint256 amount) public returns (bool);
    
    /* check if the specified new president has been approved by the parliament.
     * this function should be idempotent.
     */
    function isPresidentApproved(address newPresident) public returns (bool);
}

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

contract presidential {
    address public president;
    ParliamentInterface public parliament;

    constructor() public {
        president = msg.sender;
    }

    modifier onlyPresident {
        require(msg.sender == president);
        _;
    }

    // president can assign new parliament
    function assignParliament(address newParliament) onlyPresident public {
        require(newParliament != address(0));
        parliament = ParliamentInterface(newParliament);
    }
    
    // president can dismiss parliament
    function dismissParliament() onlyPresident public {
        delete parliament;
    }

    // everyone can try to change president but requires parliament's approval
    function changeAdministrator(address newPresident) public {
        require(parliament.isPresidentApproved(newPresident) == true);
        president = newPresident;
    }
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
}

contract BCSToken is presidential {
    using SafeMath for uint;
    
    // Public variables of the token
    string public name = "Blockcoach Community Shell";
    string public symbol = "BCS";
    uint8 public decimals = 18;
    uint public totalSupply = 0; // Starting from ZERO.
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    constructor() public {}
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens to multiple receivers.
     */
    function multiTransfer(address[] memory destinations, uint[] memory tokens) public returns (bool success) {
        assert(destinations.length > 0);
        assert(destinations.length < 128);
        assert(destinations.length == tokens.length);
        uint8 i = 0;
        uint totalTokensToTransfer = 0;
        for (i = 0; i < destinations.length; i++){
            assert(tokens[i] > 0);
            totalTokensToTransfer = totalTokensToTransfer.add(tokens[i]);
        }
        assert (balanceOf[msg.sender] > totalTokensToTransfer);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalTokensToTransfer);
        for (i = 0; i < destinations.length; i++){
            balanceOf[destinations[i]] = balanceOf[destinations[i]].add(tokens[i]);
            emit Transfer(msg.sender, destinations[i], tokens[i]);
        }
        return true;
    }
    
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    /** @notice Create `mintedAmount` tokens and send it to `target`
     *  @param target the address to receive the minted tokens
     *  @param mintedAmount the amount of tokens it will receive
     * 
     * only presidnet can initiate the mint, but requires parliament to approve the budget
     */
    function mintToken(address target, uint256 mintedAmount) onlyPresident public {
        require(parliament.hasBudgetApproved(mintedAmount) == true);
        require(parliament.consumeBudget(mintedAmount) == true); //deduct first.

        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), address(target), mintedAmount);
    }
    
}