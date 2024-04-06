import json
import warnings

from eth_account import Account
from eth_account.messages import encode_defunct
from web3 import Web3, HTTPProvider

warnings.filterwarnings("ignore")


class VerifyNftOwnership:
    """
    A collection of functions for verifying NFT ownership and signatures.
    """

    def __init__(self, contract_address: str, message: str, token_id: str, ap_id: str, signature_result: str):
        """
        Initializes the class with an Etherscan API key and Web3 provider.
        """
        with open('config.json', 'r') as config_file:
            config = json.load(config_file)
        self.Random_message = message
        self.web3 = Web3(HTTPProvider(config["web3ProviderUrl"]))
        self.contract_address = Web3.to_checksum_address(contract_address)
        self.token_id = token_id
        self.ap_id = ap_id
        self.signatureResult = signature_result
        with open("sony.json", "r") as file:
            abi_content = file.read()
        self.contract_abi = abi_content
        self.contract_instance = self.web3.eth.contract(address=self.contract_address, abi=self.contract_abi)

    def verify(self) -> bool:
        """
        Given a message and its signature, returns the Ethereum address
        corresponding to the signing  and return verify result.
        """
        result = False
        message = self.Random_message
        if len(self.signatureResult) != 132:
            return result

        try:
            if self.contract_instance.functions.getAP_ID(int(self.token_id)).call() != self.ap_id:
                print("APid:" + self.contract_instance.functions.getAP_ID(int(self.token_id)).call())
                return False
            signer_address = Account.recover_message(encode_defunct(text=message), signature=self.signatureResult)
            result = self.contract_instance.functions.connectToWifiAuthentication(signer_address, int(self.token_id)). \
                call()
        except ValueError as e:
            raise ValueError(f'Signature error: {e}') from None

        return result

    # def getRemainingUsageTime(self) -> int:
    #     """
    #     Get the remaining usable time
    #     :return Remaining usable time:
    #     """
    #     remainingUsageTime = self.contract_instance.functions.getRemainingUsageTime(int(self.token_id)).call()
    #     return remainingUsageTime

    def getExpirationTime(self) -> int:
        """
        Get expiration date
        :return  expiration date:
        """
        expirationTime = self.contract_instance.functions.getExpirationTime(int(self.token_id)).call()
        return expirationTime
