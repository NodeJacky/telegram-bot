#!/bin/bash

# Clear the screen
clear

# Define a function to print the text with a typing effect
print_with_typing_effect() {
    text="$1"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:i:1}"
        sleep 0.1
    done
    echo
}

# Define a function to create a delete effect
delete_effect() {
    text="$1"
    for (( i=${#text}; i>0; i-- )); do
        echo -n "${text:0:i}"
        sleep 0.1
        echo -ne "\r"
        echo -n "          "
        echo -ne "\r"
    done
}

# Define the banner text
banner_text="██╗    ██╗███████╗██████╗      ██╗ █████╗  ██████╗██╗  ██╗
██║    ██║██╔════╝██╔══██╗    ███║██╔══██╗██╔════╝██║ ██╔╝
██║ █╗ ██║█████╗  ██║  ██║    ╚██║███████║██║     █████╔╝ 
██║███╗██║██╔══╝  ██║  ██║     ██║██╔══██║██║     ██╔═██╗ 
╚███╔███╔╝███████╗██████╔╝     ██║██║  ██║╚██████╗██║  ██╗
 ╚══╝╚══╝ ╚══════╝╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"

# Print the banner with typing effect
print_with_typing_effect "$banner_text"

# Wait for a moment
sleep 1

# Delete the banner with delete effect
delete_effect "$banner_text"

# Wait before starting the installation
sleep 1

# Clear the screen again
clear
echo -e "\e[32mStarting Web Jack Bot Installer...\e[0m"
sleep 2

# Update and install dependencies
echo "Updating system and installing required dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv screen nano

# Set up the bot directory and virtual environment
echo "Setting up bot directory and virtual environment..."
mkdir -p ~/telegram-bot
cd ~/telegram-bot
python3 -m venv venv
source venv/bin/activate

# Install necessary Python packages
echo "Installing necessary Python packages..."
pip install telethon

# Create the bot's Python script
echo "Creating bot script..."
cat << 'EOF' > bot.py
import json
import re
from telethon import TelegramClient, events

# Load configuration
with open('config.json', 'r') as config_file:
    config = json.load(config_file)

api_id = config['api_id']
api_hash = config['api_hash']
groups = config['groups']
maestro_bot_id = config['maestro_bot_id']

sent_addresses_file = 'sent_addresses.json'

# Load previously sent addresses, if any
try:
    with open(sent_addresses_file, 'r') as f:
        sent_addresses = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    sent_addresses = []

client = TelegramClient('bot_session', api_id, api_hash)

# Define Ethereum contract address pattern
ethereum_contract_regex = r'0x[a-fA-F0-9]{40}'

# Handle new messages
@client.on(events.NewMessage(chats=groups))
async def handler(event):
    message = event.message.message
    sender_id = event.chat_id
    contract_addresses = re.findall(ethereum_contract_regex, message)

    if contract_addresses:
        new_addresses = []
        for address in contract_addresses:
            if address not in sent_addresses:
                print(f"New contract address found: {address}, group ID: {sender_id}")
                await client.send_message(maestro_bot_id, f'New Ethereum contract address: {address}')
                print(f"Successfully sent to {maestro_bot_id}: {address}")
                sent_addresses.append(address)
                new_addresses.append(address)
            else:
                print(f"Address already sent: {address}")
        if new_addresses:
            with open(sent_addresses_file, 'w') as f:
                json.dump(sent_addresses, f)

# Start the bot
client.start()
print("Bot is running...")
client.run_until_disconnected()
EOF

# Create configuration file template
echo "Creating configuration file template..."
cat << 'EOF' > config.json
{
    "api_id": "YOUR_API_ID",
    "api_hash": "YOUR_API_HASH",
    "groups": [123456789, 987654321],
    "maestro_bot_id": "@maestro"
}
EOF

# Notify user to update config.json
echo "Installation complete. Please update the 'config.json' file with your API details and group IDs."

# Navigate to the bot directory
cd ~/telegram-bot
