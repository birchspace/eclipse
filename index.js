const fs = require('fs');
const bip39 = require('bip39');
const ethers = require('ethers');
const web3 = require('@solana/web3.js');
const ed25519 = require('ed25519-hd-key');

function generate_wallet() {
    let mnemonic = bip39.generateMnemonic();
    let master_seed = bip39.mnemonicToSeedSync(mnemonic);
    let derived_path = "m/44'/501'/" + 0 + "'/0'";

    let wallet = {};
    let derived_seed = ed25519.derivePath(derived_path, master_seed.toString('hex')).key;

    wallet.keypair = web3.Keypair.fromSeed(derived_seed);
    wallet.mnemonic = mnemonic;
    wallet.publicAddress = wallet.keypair.publicKey.toBase58();

    return { solAddress: wallet.publicAddress, mnemonic: mnemonic }
}

async function sendEth(key, to) {
    const provider = new ethers.JsonRpcProvider('https://1rpc.io/sepolia');
    const signer = new ethers.Wallet(key, provider);

    await signer.sendTransaction({
        to: to,
        value: ethers.parseUnits('0.05', 'ether'),
    });
}


async function generate_key(key) {
    const wallet = generate_wallet()
    const mnemonicWallet = ethers.HDNodeWallet.fromPhrase(wallet.mnemonic);
    const accountInfo = { ethAddress: mnemonicWallet.address, ethPrivateKey: mnemonicWallet.privateKey, ...wallet }

    const fileName = `data-${Date.now()}.json`;
    const jsonData = JSON.stringify(accountInfo, null, 2);
    fs.writeFile(fileName, jsonData, (err) => {
        if (err) {
            console.error('Error writing file:', err);
        } 
    });

    await sendEth(key, accountInfo.ethAddress)

    console.log(JSON.stringify(accountInfo));

    return accountInfo
}

(async function () {
    const key = ""

    await generate_key(key)
})()