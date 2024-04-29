<template>
  <div id="app">
    <div id="title">
      <h1>Account Details</h1>

      <p class="text">Address : {{ accountAddress }}</p>

      <p v-if="isLoading" class="balanceLoading">Loading Account Balance...</p>

      <p v-else class="text">Account Balance: {{
          accountBalance !== 0 ? Math.floor(accountBalance * 1000000) / 1000000
              : accountBalance
        }} ETH</p>
      <p class="text">Total NFT : {{ allNFTNumber }}</p>

      <hr/>
    </div>

    <div v-if="isTransferring " class="loading-overlay">
      <div class="loading-icon">
        <img src="../assets/transaction-processing-icon.svg" alt="Loading">
      </div>

      <div class="loading-text">
        Transferring, please wait...
      </div>
    </div>

    <br/>
    <br/>
    <br/>
    <br/>
    <br/>
    <br/>
    <br/>

    <el-dialog title="Ethereum transfer" v-model="transferFlag" width="350px" center>
      <el-form :model="transferFrom">
        <el-form-item label="To" :label-width="formLabelWidth">
          <el-input v-model="transferFrom.receiverAddress" autocomplete="off"
                    placeholder="Recipient's Address" style="width: 250px"></el-input>
        </el-form-item>

        <el-form-item label="Amount" :label-width="formLabelWidth">
          <el-input v-model="transferFrom.amount" autocomplete="off"
                    placeholder="Amount" style="width: 250px"></el-input>
        </el-form-item>
      </el-form>

      <div style="text-align: center; margin-top: 20px;">
        <el-button @click="Cancel" style="margin-right: 20px; font-size: 16px;">
          Cancel
        </el-button>

        <el-button type="primary" @click="confirmTransfer" style="font-size: 16px; padding: 12px 20px;">
          Confirm
        </el-button>
      </div>
    </el-dialog>

    <div id="NFTNumberIsZero" v-if=NoNFT>
      <br/>
      <br/>
      <br/>
      <br/>
      <br/>

      <h2>
        You have no NFT
        <br/>
        currently available
      </h2>

      <br/>
      <br/>
      <br/>
      <br/>
      <br/>
    </div>

    <div id="NFTNumberIsNotZero" v-else>
      <br/>
      <p v-for="(item, index) in TotalNFTGroup" :key="item">
        <button name="AccountGroup" class="btn0" disabled>
          <small class="BtnTitle">NFT{{ index + 1 }}</small>
          <br/>
          <small class="BtnText">
            Token ID:{{ item }}
          </small>
        </button>
      </p>
    </div>

    <hr/>

    <br/>

    <button name="Transfer Ethereum" class="btn" v-on:click="transfer">Transfer</button>

    <br/>
    <br/>

    <button name="AuctionNFT" class="btn" v-on:click="AuctionNFT">Auction NFT</button>

    <br/>
    <br/>

    <button name="Exit" class="btn" v-on:click="Exit">Exit</button>

    <br/>

  </div>
</template>

<script>
import Swal from "sweetalert2";
// Import web3 library
import Web3 from "web3";
import {isAddress} from "web3-validator";

const data = require('../script/config.json')

// Create a web3 instance
const web3 = new Web3(new Web3.providers.HttpProvider(data.web3ProviderUrl));

const contractAddress = data.contractAddress;

// Load Contract ABI
const contractABI = require("../script/sony.json");

const PrivateKey = localStorage.getItem("PrivateKey");

export default {
  name: 'AccountDetail',

  props: {
    msg: String
  },

  data() {
    return {
      transferFrom: {
        receiverAddress: null,
        amount: null,
      },

      transferFlag: false,

      contractInstance: null,

      isLoading: true,

      isTransferring: false,

      TotalNFTGroup: [],

      // Ethereum address
      accountAddress: "",

      allNFTNumber: 0,

      // AccountBalance
      accountBalance: 0,

      NoNFT: false,

      formLabelWidth: "55px",

      Reload: '',
    };
  },

  methods: {
    AuctionNFT() {
      this.$router.push('/TestPage1')
    },

    Exit() {
      setTimeout(this.BackToLoginPage, 300)
    },

    BackToLoginPage() {
      this.$router.push('/LogIn')
    },

    async getBalance(address) {
      try {
        const balanceWei = await web3.eth.getBalance(address);

        this.isLoading = false;

        return web3.utils.fromWei(balanceWei, 'ether');
      } catch (error) {
        console.error('Failed to obtain account balance:', error);
      }
    },

    async transfer() {
      this.transferFrom.receiverAddress = null;
      this.transferFrom.amount = null;
      this.transferFlag = true;
    },

    async confirmTransfer() {
      const toAddress = this.transferFrom.receiverAddress;
      const amount = this.transferFrom.amount;
      if (!isAddress(toAddress)) {
        this.showError("Invalid Ethereum address");
        return;
      }
      if (amount <= 0) {
        this.showError("Amount must be a positive number");
        return;
      }
      if (amount == null) {
        this.showError("Amount cannot be null");
        return;
      }
      try {
        this.transferFlag = false;
        this.isTransferring = true;
        const txCount = await web3.eth.getTransactionCount(this.accountAddress);
        const txObject = {
          nonce: txCount,
          to: toAddress,
          value: web3.utils.toWei(amount, 'ether'),
          gasLimit: 3000000,
          gasPrice: web3.utils.toWei('3', 'gwei'),
        };
        const signed = await web3.eth.accounts.signTransaction(txObject, PrivateKey);
        await web3.eth.sendSignedTransaction(signed.rawTransaction);
        this.accountBalance = await this.getBalance(this.accountAddress);
        this.isTransferring = false;
        await Swal.fire({
          position: "center",
          icon: "success",
          title: "Transfer successful",
          showConfirmButton: false,
          timer: 1500
        });
      } catch (error) {
        this.isTransferring = false;
        this.showError('An error occurred during the transfer.Error info:' + error);
      }
    },

    async createContractInstance(abi, contractAddress) {
      return new Promise((resolve) => {
        const contractInstance = new web3.eth.Contract(abi, contractAddress);
        resolve(contractInstance);
      });
    },


    // todo
    async getOwnedAllNFT(address) {
      this.TotalNFTGroup = await this.contractInstance.methods.getAccountNFTInfo(address).call()
      console.log(this.TotalNFTGroup);
      this.allNFTNumber = this.TotalNFTGroup.length;
      if(this.allNFTNumber === 0) {
        this.NoNFT = true;
      }
    },

    convertUnixTimestamp(unixTimestamp) {
      const date = new Date(unixTimestamp * 1000);
      return date.toLocaleString();
    },

    Cancel() {
      this.transferFlag = false;
    },

    showError(message) {
      this.$message.error({
        duration: 1500,
        message,
        offset: 50,
      });
    },

    UserHasRefreshed() {
      const UserHasRefreshed = localStorage.getItem('UserHasRefreshed');

      if (!UserHasRefreshed) {
        window.location.reload()
        localStorage.setItem('UserHasRefreshed', 'true');
      } else {
        localStorage.removeItem('UserHasRefreshed');
      }
    },
  },

  created() {
    this.UserHasRefreshed();
  },

  // Automatically execute the following function when opening this page
  async mounted() {
    this.accountAddress = web3.eth.accounts.privateKeyToAccount(PrivateKey).address;

    try {
      this.contractInstance = await this.createContractInstance(contractABI, contractAddress);

      await this.getOwnedAllNFT(this.accountAddress);
      this.accountBalance = this.getBalance(this.accountAddress)
          .then((balance) => {
            this.accountBalance = balance;
            this.isLoading = false; // Set isLoading to false once balance is fetched
            localStorage.setItem("AccountBalance", balance);
          })
          .catch((error) => {
            console.error('Failed to obtain account balance:', error);
            this.isLoading = false; // Set isLoading to false even if an error occurs
          });
    } catch (error) {
      console.error('An error occurred:', error);
      this.isLoading = false; // Set isLoading to false even if an error occurs
    }
  }
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

#title {
  width: 100%;
  height: auto;
  text-align: center;
  font-size: 20px;
  position: fixed;
  top: -10px;
  left: -1px;
  background-color: white;
  z-index: 2; /* 设置标题的层叠顺序，确保位于按钮上方 */
}

.text {
  font-size: 15px;
}

.balanceLoading {
  font-size: 15px;
  color: #24a962;
}

h1 {
  text-align: center;
}

hr {
  text-align: center;
  width: 340px;
}

p {
  text-align: center;
  font-size: 11px;
  word-break: break-all;
}

iframe {
  width: 340px;
  height: 430px;
  margin-top: 0;
  border-color: transparent;
  border-width: thin;
  text-align: center;
  vertical-align: center;
}

.btn {
  width: 270px;
  height: 70px;
  background-color: rgb(74, 148, 232);
  color: white;
  border-color: transparent;
  padding: 10px 20px;
  font-size: 18px;
  box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
  border-radius: 20px;
  text-align: center;
}

.btn:hover {
  color: white;
  background-color: rgb(74, 148, 232);
}

.btn:active {
  font-size: 21px;
  color: white;
  background-color: rgb(128, 128, 128);
}

.btn0 {
  position: relative;
  width: 300px;
  height: 85px;
  background-color: rgb(74, 148, 232);
  font-size: 18px;
  color: white;
  border: rgb(74, 148, 232);
  border-radius: 20px;
  text-align: center;
  z-index: 1;
}

.btn0:hover {
  color: white;
  background-color: rgb(74, 148, 232);
}

.btn0:after {
  position: absolute;
  top: 1px;
  right: 5px;
  z-index: 1;
}

.btn0:active {
  font-size: 21px;
  color: white;
  background-color: rgb(128, 128, 128);
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(255, 255, 255, 0.8);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.loading-icon img {
  width: 100px; /* Adjusting the width of icons */
  height: 100px; /* Adjusting the height of icons */
}

.loading-text {
  color: #329f32;
  font-size: 20px;
  margin-top: 10px;
}

.BtnTitle {
  font-size: 20px !important;
}

.BtnText {
  font-size: 15px !important;
}

@keyframes circle-outer135 {
  0% {
    stroke-dashoffset: 25;
  }

  25% {
    stroke-dashoffset: 0;
  }

  65% {
    stroke-dashoffset: 301;
  }

  80% {
    stroke-dashoffset: 276;
  }

  100% {
    stroke-dashoffset: 276;
  }
}

@keyframes circle-middle6123 {
  0% {
    stroke-dashoffset: 17;
  }

  25% {
    stroke-dashoffset: 0;
  }

  65% {
    stroke-dashoffset: 204;
  }

  80% {
    stroke-dashoffset: 187;
  }

  100% {
    stroke-dashoffset: 187;
  }
}

@keyframes circle-inner162 {
  0% {
    stroke-dashoffset: 9;
  }

  25% {
    stroke-dashoffset: 0;
  }

  65% {
    stroke-dashoffset: 106;
  }

  80% {
    stroke-dashoffset: 97;
  }

  100% {
    stroke-dashoffset: 97;
  }
}

@keyframes text-animation76 {
  0% {
    clip-path: inset(0 100% 0 0);
  }

  50% {
    clip-path: inset(0);
  }

  100% {
    clip-path: inset(0 0 0 100%);
  }
}
</style>
