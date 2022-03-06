// info about the license
// SPDX-License-Identifier: MIT

// indicates you must use at least 0.8.0 solidity for the code
pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// hardhat tool to debug
import "hardhat/console.sol";

// importing pre-written code to encode data to Base64
import "./libraries/Base64.sol";

// what the contract does
contract my_game is ERC721 {
    // holding character attributes in a struct
    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }

    // holding big boss data
    struct BigBoss {
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }

    BigBoss public bigBoss;

    // the tokenId is the NFTs unique identifier
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // array to hold default data of characters
    CharacterAttributes[] defaultCharacters;

    // mapping from the nft's tokenId to the NFT attributes
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    // a mapping from an address to the NFTs tokenId. easy way to store owner of the NFT
    mapping(address => uint256) public nftHolders;

    // events to trigger in UI
    event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);

    // data passed into contract when first created to initialize characters
    // we will pass these values in from run.js
    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint[] memory characterHp,
        uint[] memory characterAttackDmg,
        string memory bossName,
        string memory bossImageURI,
        uint bossHp,
        uint bossAttackDamage
        // special identifier for name and symbol for token
    )
        ERC721("Rappers", "RAP")
    {

        bigBoss = BigBoss ({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            attackDamage: bossAttackDamage
        });

        console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

        // loop through all characters and save values in contract to use later on
        for (uint i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(CharacterAttributes({
                characterIndex: i,
                name: characterNames[i],
                imageURI: characterImageURIs[i],
                hp: characterHp[i],
                maxHp: characterHp[i],
                attackDamage: characterAttackDmg[i]
            }));

            CharacterAttributes memory c = defaultCharacters[i];
            console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
        }
            _tokenIds.increment();
    }

    // users would be able to get their NFT based on characterID they send in
    function mintCharacterNFT(uint _characterIndex) external {
        // this starts at 1 since we incremented it a few lines above
        uint256 newItemId = _tokenIds.current();
        // assigns the tokenId to the caller's wallet address
        // msg.sender is provided by Solidity and gives us access to the public address of the person calling the contract
        _safeMint(msg.sender, newItemId);
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage
        });

        console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);

        // easy way to see who owns what NFT
        nftHolders[msg.sender] = newItemId;
        
        // increment the tokenId for the next person to use it
        _tokenIds.increment();
        
        // trigger event to notify player their nft has been minted
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    // return NFT metadata
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

        string memory json = Base64.encode(
          abi.encodePacked(
            '{"name": "',
            charAttributes.name,
            ' -- NFT #: ',
            Strings.toString(_tokenId),
            '", "description": "This is an NFT that lets people play in the game Rap Defender!", "image": "',
            charAttributes.imageURI,
            '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
            strAttackDamage,'} ]}'
          )
        );

        string memory output = string(
          abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    // attacks the boss in the game
    function attackBoss() public {
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
        console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
        console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);

        require (
            player.hp > 0,
            "Error: character must have HP to attack boss."
        );

        require (
          bigBoss.hp > 0,
          "Error: boss must have HP to attack boss."  
        );

        if (bigBoss.hp < player.attackDamage) {
            bigBoss.hp = 0;
        } 
        else {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
        }

        if (player.hp < bigBoss.attackDamage) {
            player.hp = 0;
        }
        else {
            player.hp = player.hp - bigBoss.attackDamage;
        }

        // trigger event that attack is complete to notify player
        emit AttackComplete(bigBoss.hp, player.hp);

        console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);
    }

    function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
        // get the tokenId of the user's character NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // if the user has a tokenID in the map, return their character
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // else return an empty character
        else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
        return defaultCharacters;
    }

    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }
}