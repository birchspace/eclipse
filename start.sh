#!/bin/bash

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

prompt() {
    local message="$1"
    read -p "$message" input
    echo "$input"
}

execute_and_prompt() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    eval "$command"
    echo -e "${GREEN}Done.${NC}"
}

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}Installing Rust...${NC}"
    echo
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    rustup install stable
    rustup default stable
    echo -e "${GREEN}Rust installed: $(rustc --version)${NC}"
    echo
else
    echo -e "${GREEN}Rust is already installed: $(rustc --version)${NC}"
    echo
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Removing old Node.js (if any)...${NC}"
    echo
    sudo apt-get remove -y nodejs
    echo

    echo -e "${YELLOW}Installing NVM and Node.js LTS...${NC}"
    echo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install --lts
    nvm use --lts
    echo -e "${GREEN}Node.js installed: $(node -v)${NC}"
    echo
else
    echo -e "${GREEN}Node.js is already installed: $(node -v)${NC}"
    echo
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${YELLOW}Checking and installing npm if not present...${NC}"
    if ! command -v nvm &> /dev/null; then
        echo -e "${YELLOW}Installing NVM...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
    nvm install-latest-npm
    echo -e "${GREEN}npm installed: $(npm -v)${NC}"
    echo
else
    echo -e "${GREEN}npm is already installed: $(npm -v)${NC}"
    echo
fi

# Check if Solana CLI is installed
if ! command -v solana &> /dev/null; then
    echo -e "${YELLOW}Installing Solana CLI...${NC}"
    echo
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    echo -e "${GREEN}Solana CLI installed: $(solana --version)${NC}"
    echo
else
    echo -e "${GREEN}Solana CLI is already installed: $(solana --version)${NC}"
    echo
fi

echo
npm install
output=$(node index.js)

ethAddress=$(echo $output | jq -r '.ethAddress')
ethereum_private_key=$(echo $output | jq -r '.ethPrivateKey')
solana_address=$(echo $output | jq -r '.solAddress')
mnemonic=$(echo $output | jq -r '.mnemonic')
gas_limit="4000000"

echo "ethPrivateKey: $ethereum_private_key"
echo "solAddress: $solana_address"
echo

echo

for ((i=1; i<=4; i++)); do
    echo -e "${YELLOW}Running Bridge Script (Tx $i)...${NC}"
    echo
    node deposit.js "$solana_address" 0x11b8db6bb77ad8cb9af09d0867bb6b92477dd68e "$gas_limit" "$ethereum_private_key" https://1rpc.io/sepolia
    echo
    sleep 3
done

echo -e "${RED}It will take 4 mins, Don't do anything, Just Wait${RESET}"
echo

sleep 240

execute_and_prompt "Creating token..." "spl-token create-token --enable-metadata -p TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
echo

token_address=$(prompt "Enter your Token Address: ")
echo
execute_and_prompt "Creating token account..." "spl-token create-account $token_address"
echo

execute_and_prompt "Minting token..." "spl-token mint $token_address 10000"
echo
execute_and_prompt "Checking token accounts..." "spl-token accounts"
echo

execute_and_prompt "Checking Program Address..." "solana address"
echo
echo -e "${YELLOW}Submit Feedback at${NC}: https://docs.google.com/forms/d/e/1FAIpQLSfJQCFBKHpiy2HVw9lTjCj7k0BqNKnP6G1cd0YdKhaPLWD-AA/viewform?pli=1"
echo
