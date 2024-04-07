import lorem

import sys
from itertools import chain
import random
import hashlib
import base64
from web3 import Web3
from web3.exceptions import InvalidAddress
from brownie import network, web3, accounts, Wei, AnonIDContract, LamportBase2, Contract
from brownie.network import gas_price
from brownie.network.gas.strategies import LinearScalingStrategy
from eth_utils import encode_hex #, encode
from eth_abi import encode
from Crypto.Hash import keccak
from typing import List
import json
import os
import ast
import time
from time import sleep
import re
from typing import List
import struct
from offchain.local_functions import get_pkh_list
from offchain.KeyTracker_ import KeyTracker
from offchain.soliditypack import solidity_pack_value_bytes, solidity_pack_value, pack_keys, encode_packed_2d_list, solidity_pack_bytes, encode_packed, solidity_pack_pairs, solidity_pack, solidity_pack_bytes, solidity_pack_array
from offchain.Types import LamportKeyPair, Sig, PubPair
from offchain.functions import hash_b, sign_hash, verify_signed_hash
from eth_abi import encode, encode
from binascii import crc32, hexlify
import binascii
from offchain.crc import compute_crc
#from offchain.oracle_functions import extract_data_from_file, get_pkh_list, send_pkh_with_crc, save_received_data, read_till_eof, send_packed_file
import offchain.data_temp

SOF = b'\x01'  # Start Of File marker
EOF = b'\x04'  # End Of File marker
CRC_START = b'<CRC>'
CRC_END = b'</CRC>'



gas_strategy = LinearScalingStrategy("120 gwei", "1200 gwei", 1.1)

# if network.show_active() == "development":
gas_price(gas_strategy)

# ITERATIONS = 3

# def compute_crc(self, data: str) -> int:
#     return crc32(data.encode())

offchain.data_temp.received_data = b''

def encode_packed(*args):
    return b"".join([struct.pack(f"<{len(arg)}s", arg) for arg in args])


def custom_encode_packed(address, integer):
    # Convert the address to bytes and pad with zeroes
    address_bytes = bytes(Web3.toBytes(hexstr=address))

    # Convert the integer to bytes and pad with zeroes
    integer_bytes = encode('uint', integer)

    # Concatenate everything together
    result = address_bytes + b'\0' * 12 + integer_bytes + b'\0' * 12

    return result.decode('unicode_escape')

def main():
    for _ in range(1):  # This will repeat the whole logic 3 times
        lamport_test = LamportTest()
        
        # Convert all account objects to strings before passing them
        lamport_test.can_test_key_functions([str(acc) for acc in accounts])


oracle_pkh = []
master_pkh_1 = []
master_pkh_2 = []
master_pkh_3 = []
master_pkh_4 = []

class LamportTest:
    
    def __init__(self):

        self.k1 = KeyTracker("master1") # new keys made here
        self.k2 = KeyTracker("master2")
        self.k3 = KeyTracker("oracle1")
        self.k4 = KeyTracker("master3")
        print("Initializing LamportTest...")
        with open('contract_AnonID.txt', 'r') as file:
            contract_address = file.read().strip()
        #print(contract_address)
        self.contract = AnonIDContract.at(contract_address)
        #lamport_base = LamportBase.at(contract_address) # <<< not working!
        accounts.default = str(accounts[0]) 
        # link it up
        pkhs = self.get_pkh_list(self.contract, 0)
        opkhs = self.get_pkh_list(self.contract, 1)
        # priv level set here with integer ^
        print("contract pkh", pkhs)

        self.load_two_masters(pkhs, "master")
        self.load_keys(opkhs, "oracle")
        print('init done')

    def get_pkh_list(self, contract, privilege_level):
        with open('contract_LamportBase2.txt', 'r') as file:
            contract_address = file.read().strip()
        contract2 = LamportBase2.at(contract_address)

        contract_pkh = str(contract2.getPKHsByPrivilege(privilege_level))
        # gonna need some kind of wait / delay here for primetime
        print(contract_pkh)
        contract_pkh_list = re.findall(r'0x[a-fA-F0-9]+', contract_pkh)
        pkh_list = [pkh for pkh in contract_pkh_list]  # Removing '0x' prefix
        contract_pkh_string = json.dumps(contract_pkh)
        contract_pkh_list = json.dumps(contract_pkh_string)
        return pkh_list

    
    def load_two_masters(self, pkhs, filename):
        pkh_index = 0
        master1_loaded = False
        master2_loaded = False
        master3_loaded = False
        master4_loaded = False
        global master_pkh_1
        global master_pkh_2
        global master_pkh_3
        global master_pkh_4

        while not master1_loaded and pkh_index < len(pkhs):
            try:
                self.k1.load(self, filename + '1', pkhs[pkh_index])
                print(f"Load successful for Master 1, PKH: {pkhs[pkh_index]}")
                master1_loaded = True
                key_tracker_1 = self.k1.current_key_pair()
                master_pkh_1 = pkhs[pkh_index]
                pkh_index += 1  # increment the pkh_index after successful load
            except InvalidAddress:
                print(f"No valid keys found for Master 1, PKH: {pkhs[pkh_index]}")
                pkh_index += 1  # increment the pkh_index if load failed

        if not master1_loaded:
            print("Load failed for all provided PKHs for Master 1")
            return

        while not master2_loaded and pkh_index < len(pkhs):
            try:
                self.k2.load(self, filename + '2', pkhs[pkh_index])
                print(f"Load successful for Master 2, PKH: {pkhs[pkh_index]}")
                master2_loaded = True
                key_tracker_2 = self.k2.current_key_pair()
                master_pkh_2 = pkhs[pkh_index]
                pkh_index += 1  # increment the pkh_index after successful load
            except InvalidAddress:
                print(f"No valid keys found for Master 2, PKH: {pkhs[pkh_index]}")
                pkh_index += 1  # increment the pkh_index if load failed

        if not master2_loaded:
            print("Load failed for all provided PKHs for Master 2")

        while not master3_loaded and pkh_index < len(pkhs):
            try:
                self.k4.load(self, filename + '3', pkhs[pkh_index])
                print(f"Load successful for Master 3, PKH: {pkhs[pkh_index]}")
                master3_loaded = True
                key_tracker_3 = self.k4.current_key_pair()
                master_pkh_3 = pkhs[pkh_index]
                pkh_index += 1  # increment the pkh_index after successful load
            except InvalidAddress:
                print(f"No valid keys found for Master 3, PKH: {pkhs[pkh_index]}")
                pkh_index += 1  # increment the pkh_index if load failed

        if not master4_loaded:
            print("Load failed for all provided PKHs for Master 3")

        while not master4_loaded and pkh_index < len(pkhs):
            try:
                self.k5.load(self, filename + '4', pkhs[pkh_index])
                print(f"Load successful for Master 4, PKH: {pkhs[pkh_index]}")
                master4_loaded = True
                key_tracker_4 = self.k5.current_key_pair()
                master_pkh_4 = pkhs[pkh_index]
                pkh_index += 1  # increment the pkh_index after successful load
            except InvalidAddress:
                print(f"No valid keys found for Master 4, PKH: {pkhs[pkh_index]}")
                pkh_index += 1  # increment the pkh_index if load failed

        if not master4_loaded:
            print("Load failed for all provided PKHs for Master 2")            

    def load_keys(self, pkhs, filename):
        global oracle_pkh
        for pkh in pkhs:
            try:
                oracle_pkh = pkh
                self.k3.load(self, filename + '1', pkh)
                print(f"Load successful for PKH: {pkh}")
                return  # Exit function after successful load
            except InvalidAddress:
                print(f"No valid keys found for PKH: {pkh}")
                continue  # Try the next pkh if this one fails
        print("Load failed for all provided PKHs")

    def can_test_key_functions(self, accs):
        global master_pkh_1
        global master_pkh_2
        global master_pkh_3
        global master_pkh_4
        print("Running 'can_test_key_functions'...")
        with open('contract_AnonID.txt', 'r') as file:
            contract_address = file.read()
            contract_address = contract_address.strip().replace('\n', '')  # Remove whitespace and newlines

        _contract = AnonIDContract.at(contract_address)
        print("Contract referenced.")
        print('master_pkh_3', master_pkh_3)
        private_key = '163f5f0f9a621d72fedd85ffca3d08d131ab4e812181e0d30ffd1c885d20aac7'
        brownie_account = accounts.add(private_key)
        current_keys = self.k4.load(self, "master3", master_pkh_1)
        current_pkh = self.k4.pkh_from_public_key(current_keys.pub)
        print('current pkh', current_pkh)
        next_keys = self.k4.get_next_key_pair()
        nextpkh = self.k4.pkh_from_public_key(next_keys.pub)
        #pairs = generate_address_value_pairs(10)
        #packed_pairs = solidity_pack_pairs(pairs)
        #_newCap = int(300000)
        #numToBroadcast = int(1000000)
        #pnumToBroadcast = numToBroadcast.to_bytes(4, 'big')
        #paddednumToBroadcast = solidity_pack_value_bytes(pnumToBroadcast)
        #paddressToBroadcast = '0x99a840C3BEEe41c3F5B682386f67277CfE3E3e29' # activity contract needing approval
        with open('contract_PlayerDatabase-coin.txt', 'r') as file:
            contract_address2 = file.read()
            contract_address2 = contract_address2.strip().replace('\n', '') 
        paddressToBroadcast = contract_address2
        packed_message = str.lower(paddressToBroadcast)[2:].encode() + nextpkh[2:].encode()

        callhash = hash_b(str(packed_message.decode()))
        sig = sign_hash(callhash, current_keys.pri) 
        private_key = '163f5f0f9a621d72fedd85ffca3d08d131ab4e812181e0d30ffd1c885d20aac7'
        brownie_account = accounts.add(private_key)
        
        _contract.grantActivityContractPermissionStepOne(
            current_keys.pub,
            sig,
            nextpkh,
            paddressToBroadcast,
            {'from': brownie_account}    
        )
        self.k4.save(trim = False)
        #self.k4.save(trim = False)
        master_pkh_3 = nextpkh

        current_keys = self.k5.load(self, "master4", master_pkh_4)
        next_keys = self.k5.get_next_key_pair()
        nextpkh = self.k5.pkh_from_public_key(next_keys.pub)

        #paddressToBroadcast = '0xfd003CA44BbF4E9fB0b2fF1a33fc2F05A6C2EFF9'

        packed_message = str.lower(paddressToBroadcast)[2:].encode() + nextpkh[2:].encode()

        callhash = hash_b(str(packed_message.decode()))
        sig = sign_hash(callhash, current_keys.pri) 


        
        _contract.grantActivityContractPermissionStepTwo(
            current_keys.pub,
            sig,
            nextpkh,
            #paddressToBroadcast,
            {'from': brownie_account}    
        )
        self.k5.save(trim = False)
        exit()