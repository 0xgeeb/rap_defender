const main = async () => {
    // will compile contract and generate necessary files in artifacts directory
    const gameContractFactory = await hre.ethers.getContractFactory('my_game');
    // hardhat creates a local eth network to work on
    // it is like using a local server, creates a blank state so debugging is easy
    const gameContract = await gameContractFactory.deploy(
        ["thug", "carti", "cole"],
        ["https://i.scdn.co/image/ab677762000056b8df39ab702680d7977e5cd684",
        "https://media.pitchfork.com/photos/5c42708f973b5279a897020b/4:3/w_524,h_393,c_limit/Playboi-Carti.jpg",
        "https://www.biography.com/.image/ar_1:1%2Cc_fill%2Ccs_srgb%2Cfl_progressive%2Cq_auto:good%2Cw_1200/MTQ3Mzg3MjY0ODg2OTA4NTk5/j_cole_photo_by_isaac_brekken_wireimage_getty_503069628.jpg"],
        [100, 100, 150], // hp values
        [25, 25, 35], // attack damage values
        "Tom MacDonald", // boss name
        "https://i.pinimg.com/736x/e8/5f/6f/e85f6f5e717a4a538e48ea36a4c7ec1b.jpg", // boss image
        1000, // boss hp
        50 // boss attack damage
    );
    // wait until contract is officially mined and deployed to local blockchain
    await gameContract.deployed();
    // this will run and print when contract is actually deployed
    console.log("Contract deployed to:", gameContract.address);

    // previous deploys below
    
    // let txn;

    // txn = await gameContract.mintCharacterNFT(0);
    // await txn.wait();

    // txn = await gameContract.attackBoss();
    // await txn.wait();

    // txn = await gameContract.attackBoss();
    // await txn.wait();

    // let returnedTokenUri = await gameContract.tokenURI(1);
    // console.log("Token URI:", returnedTokenUri);
};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();