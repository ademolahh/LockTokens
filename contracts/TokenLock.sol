// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

error notTime();
error notYours();
error lengthsNotEqual();
error NoTokenIdSelected();
error ContractIsPaused();
error NotEnoughAllowance();
error insufficientBalance();
error NotAnERC721Contract();
error ContractNotApproved();
error NotAnERC1155Contract();
error LockPeriodCannotBeZero();

contract TokenLock is Ownable {
    /*
     This smart contract is used to lock tokens for specific time,
     It doesnt come with reward,
     It supports Any ERC20,ERC721,ERC1155 token
     */
    bool private paused = false;

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                  Token INFO's                                          //
    ////////////////////////////////////////////////////////////////////////////////////////////

    struct MyERC721 {
        address owner;
        uint128 lockTime;
        uint128 lockPeriod;
    }
    // Mapping from the token Contract to its token, the then to its info
    mapping(address => mapping(uint256 => MyERC721)) private ERC721Info;

    struct MyERC20 {
        uint256 tokenBalance;
        uint128 lockTime;
        uint128 lockPeriod;
    }
    // Mapping from the token Contract to its owner, the then to its info
    mapping(address => mapping(address => MyERC20)) private ERC20Info;

    struct MyERC1155 {
        uint256 tokenBal;
        uint128 lockPeriod;
        uint128 lockTime;
    }
    // Mapping from the CA -> TokenID -> TokenNft Infp
    mapping(address => mapping(address => mapping(uint256 => MyERC1155)))
        private ERC1155Info;

    modifier contractStatus() {
        if (paused) revert ContractIsPaused();
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                             ERC20-Deposite-Withdrawal                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////

    /** Withdraws the an ERC72 token of the caller
     *  throws if the token address is not an ERC721 contract address
     *  throws if the caller tries to withdraw before time
     *  throws if callers is not the owner of the token
     *  lockTime updates whenever a token of same types is deposited after certain time
     *  or before the previous lockPeriod elapse
     */

    function depositeERC20(
        address _token,
        uint256 amount,
        uint128 lockPeriod
    ) public contractStatus {
        IERC20Metadata token = IERC20Metadata(_token);
        uint256 decimal = 10**token.decimals();
        if (lockPeriod == 0) revert LockPeriodCannotBeZero();
        if (amount * decimal > token.allowance(msg.sender, address(this)))
            revert NotEnoughAllowance();
        MyERC20 storage erc20 = ERC20Info[_token][msg.sender];
        if (token.balanceOf(msg.sender) < amount * decimal)
            revert insufficientBalance();
        token.transferFrom(msg.sender, address(this), amount * decimal);
        erc20.tokenBalance += amount * decimal;
        erc20.lockTime = uint128(block.timestamp);
        erc20.lockPeriod = lockPeriod;
        emit ERC20Deposite(
            _token,
            msg.sender,
            amount * decimal,
            block.timestamp
        );
    }

    function depositeBulkERC20(
        address[] calldata token,
        uint256[] calldata amount,
        uint128 lockPeriod
    ) external {
        if (token.length != amount.length) revert lengthsNotEqual();
        uint256 i;
        for (; i < token.length; ) {
            depositeERC20(token[i], amount[i], lockPeriod);
            unchecked {
                ++i;
            }
        }
    }

    /** Withdraws ERC20 token of the caller 
        throws if the caller tries to withdraw before time
        throws if callers balance is less that the amount
     */
    function withdrawErc20(address token, uint256 amount) public {
        MyERC20 storage erc20 = ERC20Info[token][msg.sender];
        uint256 balance = erc20.tokenBalance;
        uint256 decimal = 10**IERC20Metadata(token).decimals();
        if (block.timestamp - erc20.lockTime < erc20.lockPeriod)
            revert notTime();
        if (balance < amount * decimal) revert insufficientBalance();
        unchecked {
            erc20.tokenBalance -= amount;
            if (erc20.tokenBalance == 0) {
                erc20.lockPeriod = 0;
                erc20.lockTime = 0;
            }
        }
        IERC20(token).transfer(msg.sender, amount * decimal);
        emit ERC20Withdrawal(token, msg.sender, amount * decimal);
    }

    function erc20BulkWithdrawal(
        address[] calldata token,
        uint256[] calldata amount
    ) external {
        if (amount.length != token.length) revert lengthsNotEqual();
        uint256 i;
        for (; i < token.length; ) {
            withdrawErc20(token[i], amount[i]);
            unchecked {
                ++i;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                           ERC721-Deposite-Withdrawal                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////
    /** Deposite the an ERC721 token of the caller
     *  throws if the token address is not an ERC721 contract address
     *  lockTime updates whenever a token of same types is deposited after certain time
     *  or before the previous lockPeriod elapse
     */
    function depositeERC721(
        address _token,
        uint256 tokenID,
        uint256 _lockPeriod
    ) public contractStatus {
        IERC721 token = IERC721(_token);
        if (!token.isApprovedForAll(msg.sender, address(this)))
            revert ContractNotApproved();
        if (_lockPeriod == 0) revert LockPeriodCannotBeZero();
        if (token.ownerOf(tokenID) != msg.sender) revert notYours();
        IERC721(token).transferFrom(msg.sender, address(this), tokenID);
        ERC721Info[_token][tokenID] = MyERC721({
            owner: msg.sender,
            lockTime: uint128(block.timestamp),
            lockPeriod: uint128(_lockPeriod)
        });
        emit ERC721Deposite(_token, msg.sender, tokenID, block.timestamp);
    }

    function depositeBulkERC721(
        address token,
        uint256[] calldata tokenID,
        uint128 lockPeriod
    ) external {
        uint i;
        for (; i < tokenID.length; ) {
            depositeERC721(token, tokenID[i], lockPeriod);
            unchecked {
                ++i;
            }
        }
    }

    /** Withdraws the an ERC721 token of the caller
     *  throws if the token address is not an ERC721 contract address
     *  throws if the caller tries to withdraw before time
     *  throws if callers is not the owner of the token
     */

    function withdrawERC721(address token, uint256 tokenID) public {
        MyERC721 storage erc721 = ERC721Info[token][tokenID];
        if (erc721.owner != msg.sender) revert notYours();
        if (block.timestamp - erc721.lockTime < erc721.lockPeriod)
            revert notTime();
        IERC721(token).transferFrom(address(this), msg.sender, tokenID);
        ERC721Info[token][tokenID] = MyERC721({
            owner: address(0),
            lockTime: 0,
            lockPeriod: 0
        });
        emit ERC721Withdrawal(token, msg.sender, tokenID);
    }

    function bulkWithdrawERC721(address token, uint256[] calldata tokenID)
        external
    {
        if (tokenID.length == 0) revert NoTokenIdSelected();
        uint j;
        for (; j < tokenID.length; ) {
            withdrawERC721(token, tokenID[j]);
            unchecked {
                ++j;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                          ERC1155-Deposite-Withdrawal                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////

    /** Deposite the an ERC1155 token of the caller
     *  throws if the token address is not an ERC1155 contract address
     *  lockTime updates whenever a token of same types is deposited after certain time
     *  or before the previous lockPeriod elapse
     */

    function depositeERC1155(
        address _token,
        uint256 tokenID,
        uint256 amount,
        uint128 _lockPeriod
    ) public contractStatus {
        IERC1155 token = IERC1155(_token);
        if (!token.isApprovedForAll(msg.sender, address(this)))
            revert ContractNotApproved();
        if (_lockPeriod == 0) revert LockPeriodCannotBeZero();
        MyERC1155 storage erc1155 = ERC1155Info[_token][msg.sender][tokenID];
        IERC1155(token).safeTransferFrom(
            msg.sender,
            address(this),
            tokenID,
            amount,
            ""
        );
        erc1155.tokenBal += amount;
        erc1155.lockPeriod = _lockPeriod;
        erc1155.lockTime = uint128(block.timestamp);
        emit ERC1155Deposite(
            _token,
            msg.sender,
            tokenID,
            amount,
            block.timestamp
        );
    }

    function depositeBulkERC11155(
        address token,
        uint256[] calldata tokenID,
        uint256[] calldata amount,
        uint128 lockPeriod
    ) external {
        if (amount.length != tokenID.length) revert lengthsNotEqual();
        uint256 k;
        for (; k < tokenID.length; ) {
            depositeERC1155(token, tokenID[k], amount[k], lockPeriod);
            unchecked {
                ++k;
            }
        }
    }

    /** Withdraws the ERC1155 token of the caller
     *  throws if the caller tries to withdraw before time
     *  throws if callers tries withdrawing an amount greater than that of token id it own
     */

    function withdrawERC1155(
        address token,
        uint256 tokenID,
        uint256 amount
    ) public {
        MyERC1155 storage erc1155 = ERC1155Info[token][msg.sender][tokenID];
        uint256 _lockTime = erc1155.lockTime;
        if (block.timestamp - _lockTime < erc1155.lockPeriod) revert notTime();
        if (erc1155.tokenBal < amount) revert insufficientBalance();
        unchecked {
            erc1155.tokenBal -= amount;
        }
        if (erc1155.tokenBal == 0) {
            erc1155.lockPeriod = 0;
            erc1155.lockTime = 0;
        }

        IERC1155(token).safeTransferFrom(
            address(this),
            msg.sender,
            tokenID,
            amount,
            ""
        );
        emit ERC1155Withdrawal(token, msg.sender, tokenID, amount);
    }

    function erc1155BulkWithdrawal(
        address token,
        uint256[] calldata tokenID,
        uint256[] calldata amount
    ) external {
        if (amount.length != tokenID.length) revert lengthsNotEqual();
        uint256 i;
        for (; i < tokenID.length; ) {
            withdrawERC1155(token, tokenID[i], amount[i]);
            unchecked {
                ++i;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                CONTRACT-STATUS                                         //
    ////////////////////////////////////////////////////////////////////////////////////////////

    function flipContractStatus(bool _status) external onlyOwner {
        paused = _status;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                ON-RECEIVED-FUNCTIONS                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                  VIEW-PURE-FUNCTIONS                                   //
    ////////////////////////////////////////////////////////////////////////////////////////////
    function getERC20Info(address contractAddress, address account)
        external
        view
        returns (MyERC20 memory)
    {
        return ERC20Info[contractAddress][account];
    }

    function getERC721Info(address contractAddress, uint256 token)
        external
        view
        returns (MyERC721 memory)
    {
        return ERC721Info[contractAddress][token];
    }

    function getERC1155Info(
        address contractAddress,
        address account,
        uint256 tokenID
    ) external view returns (MyERC1155 memory) {
        return ERC1155Info[contractAddress][account][tokenID];
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
    //                                  EVENTS                                                //
    ////////////////////////////////////////////////////////////////////////////////////////////
    event ERC20Deposite(
        address token,
        address owner,
        uint256 amount,
        uint256 timestamp
    );

    event ERC721Deposite(
        address token,
        address owner,
        uint256 tokenID,
        uint256 timestamp
    );

    event ERC1155Deposite(
        address token,
        address owner,
        uint256 tokenID,
        uint256 amount,
        uint256 timestamp
    );
    event ERC20Withdrawal(address token, address owner, uint256 amount);

    event ERC721Withdrawal(address token, address owner, uint256 tokenID);

    event ERC1155Withdrawal(
        address token,
        address owner,
        uint256 tokenID,
        uint256 amount
    );
}
