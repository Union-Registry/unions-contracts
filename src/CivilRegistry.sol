// SPDX License Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Attestation} from "@ethsign/src/models/Attestation.sol";
import {DataLocation} from "@ethsign/src/models/DataLocation.sol";
import {ISP} from "@ethsign/src/interfaces/ISP.sol";

// on-chain NFT contract UnionRings which civil registry has permissions to mint from directly and transfer to Union recipients
interface IUnionRings {
    function mint(address account, uint256 id, bytes memory data) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}
// contract for creating and managing unions between two parties
// interfaces with onchain NFT contract that holds svg data for each ring created
// the proposer creates the ring to give to the proposee and vice versa
// rings made by proposer are minted and held by this contract until union is accepted by proposee
// this is so the proposer pays the gas fee, if they are creating a unique ring the gas fee is quite expensive to post the svg data on-chain
// same with proposee, pays gas fees to mint their NFT, which can be expensive if it is a new unique ring.

contract CivilRegistry is OwnableUpgradeable, ERC1155Holder {
    ISP public spInstance;
    address[] public exampleArray;
    IUnionRings public ringsContract;
    uint256 private unionCount;
    uint64 public schema;

    event UnionProposed(uint256 unionId);
    event UnionAccepted(uint256 unionId, uint64 attestationUid);
    event UnionRevoked(uint256 unionId);

    error NotParticipant(uint256 unionId);
    error InvalidSecret(uint256 unionId);

    // struct containing all information relating to a union
    /// @param participants array of addresses of the participants in the union
    /// @param vows array of vows made by the participants
    /// @param ringIds array of ringIds of the NFT UnionRings that are created and minted to participants in the union
    /// @param accepted boolean indicating whether the union has been accepted by the proposee
    /// @param attestationUid bytes32 uid of the attestation created by the EAS contract
    /// @param secretHash bytes32 hash of the secret phrase made by the proposer that is hashed
    struct Union {
        address[] participants;
        string[] vows;
        uint256[] ringIds;
        bytes32 secretHash;
        bool accepted;
        uint64 attestationUid;
    }

    // Union[] public unions; allows mapping and refering a given union by a number ID
    mapping(uint256 => Union) public unions;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _ringsContract  , uint64 _schema) public initializer {
        __Ownable_init(msg.sender);
        ringsContract = IUnionRings(_ringsContract);
        schema = _schema;
    }

    // intenral function that creates new Union and pushes the proposer's data into the struct
    function _propose(uint256 tokenId, string memory vow, bytes32 secretHash) internal {
        Union storage union = unions[unionCount];
        union.participants.push(msg.sender);
        union.vows.push(vow);
        union.ringIds.push(tokenId);
        union.secretHash == secretHash;
        union.accepted = false;
        emit UnionProposed(unionCount);
        unionCount++;
    }
    // internal function which accepts a union and creates an attestation in the EAS contract and pushes proposee's data into the Union struct

    function _accept(uint256 unionId, uint256 tokenId, string memory vow, string memory secret) internal {
        Union storage union = unions[unionId];
        if (keccak256(abi.encodePacked(secret)) != union.secretHash) {
            revert InvalidSecret(unionId);
        }
        if (union.participants[1] != msg.sender) {
            revert NotParticipant(unionId);
        }
        bytes[] memory recipients = new bytes[](2);
        recipients[0] = abi.encode(union.participants[0]);
        recipients[1] = abi.encode(msg.sender);
        Attestation memory a = Attestation({
            schemaId: schema,
            linkedAttestationId: 0,
            attestTimestamp: 0,
            revokeTimestamp: 0,
            attester: address(this),
            validUntil: 0,
            dataLocation: DataLocation.ONCHAIN,
            revoked: false,
            recipients: recipients,
            data: abi.encode(vow, tokenId)
        });
        uint64 attestationId = spInstance.attest(a, "", "", "");

        union.accepted = true;
        union.participants.push(msg.sender);
        union.ringIds.push(tokenId);
        union.vows.push(vow);
        union.attestationUid = attestationId;
        emit UnionAccepted(unionId, attestationId);
    }
    // external function that allows a user to propose a union
    // nft is minted from rings contract and held by this smart contract until union is accepted by proposee

    function proposeUnion(uint256 tokenId, string memory vow, bytes32 secretHash) public payable {
        uint256 currentUnionId = unionCount;
        _propose(tokenId, vow, secretHash);
        ringsContract.mint(address(this), unions[currentUnionId].ringIds[0], "");
    }

    // external function that allows a user to accept a union
    // nft is transferred from this smart contract to the proposee and a new nft is minted and transferred to the proposer
    // update union state to accepted
    function acceptUnion(uint256 unionId, uint256 tokenId, string memory vow, string memory secret) public {
        Union storage union = unions[unionId];
        _accept(unionId, tokenId, vow, secret);
        ringsContract.safeTransferFrom(address(this), union.participants[1], union.ringIds[0], 1, "");
        ringsContract.mint(union.participants[0], union.ringIds[1], "");
    }

    // helper function to get union data
    function getUnion(uint256 unionId)
        public
        view
        returns (
            address[] memory participants,
            string[] memory vows,
            uint256[] memory ringIds,
            bool accepted,
            uint64 attestationUid
        )
    {
        Union storage union = unions[unionId];
        return (union.participants, union.vows, union.ringIds, union.accepted, union.attestationUid);
    }

    // admin function to set the rings contract address

    function setRingsContract(address _ringsContract) public onlyOwner {
        ringsContract = IUnionRings(_ringsContract);
    }

}
