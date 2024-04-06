<template>
  <div id="app">
    <div id="title">
      <h1>Account Details</h1>

      <p class="text">Address : {{ Address }}</p>

      <p v-if="isLoading" class="balanceLoading">Loading Account Balance...</p>

      <p v-else class="text">Account Balance: {{
          AccountBalance !== 0 ? Math.floor(AccountBalance * 1000000) / 1000000
              : AccountBalance
        }} ETH</p>
      <p class="text">Total NFT : {{ allNFTNumber }}</p>

      <p class="text">Unexpired NFT : {{ UnexpiredNFTNumber }}</p>

      <hr/>
    </div>

    <div v-if="isConnecting" class="loading-overlay">
      <div id="wifi-loader">
        <svg class="circle-outer" viewBox="0 0 86 86">
          <circle class="back" cx="43" cy="43" r="40"></circle>
          <circle class="front" cx="43" cy="43" r="40"></circle>
          <circle class="new" cx="43" cy="43" r="40"></circle>
        </svg>
        <svg class="circle-middle" viewBox="0 0 60 60">
          <circle class="back" cx="30" cy="30" r="27"></circle>
          <circle class="front" cx="30" cy="30" r="27"></circle>
        </svg>
        <svg class="circle-inner" viewBox="0 0 34 34">
          <circle class="back" cx="17" cy="17" r="14"></circle>
          <circle class="front" cx="17" cy="17" r="14"></circle>
        </svg>
        <div class="wifi-loader-text" data-text="Verifying..."></div>
      </div>
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
      <p v-for="(item, index) in UnexpiredNFT" :key="item">
        <button name="AccountGroup" class="btn0" v-on:click="connectionConfirmation(item)">
          <small class="BtnTitle">NFT{{ index + 1 }}</small>
          <br/>
          <small class="BtnText">

            Token ID:{{ item }} &nbsp; AP ID:{{ NFTtoAPMapping[item] }}
          </small>
          <br/>
          <small class="BtnText">
            &nbsp;Expire Date:{{ convertUnixTimestamp(Number(expirationTimeList[this.TotalNFTGroup.indexOf(item)])) }}
          </small>
        </button>
      </p>

      <br/>

      <div v-if="this.ExpiredNFTNumber !== 0">
        <p id="ExpiredNFT">The following are expired NFTs</p>

        <small id="ExpiredNFTNumber">Expired NFT : {{ ExpiredNFTNumber }}</small>
      </div>

      <p v-for="(item, index) in ExpiredNFT" :key="item">
        <button name="AccountGroup" class="btn1" disabled>
          <small class="BtnTitle">NFT {{ index + 1 }}</small>
          <br/>
          <small class="BtnText">Token ID:{{ item }} &nbsp; AP ID:{{ NFTtoAPMapping[item] }}</small>
          <br/>
          <small class="BtnText">
            Expire Date:{{ convertUnixTimestamp(Number(expirationTimeList[this.TotalNFTGroup.indexOf(item)])) }}
          </small>
        </button>
      </p>
    </div>

    <hr/>

    <button name="Transfer Ethereum" class="btn" v-on:click="transfer">Transfer</button>

    <br/>
    <br/>

    <button name="PurchaseNFT" class="btn" v-on:click="PurchaseNFT">Buy NFT</button>

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

const hostIP = window.location.host;

const IpAddress = hostIP.split(':')[0];

const data = require('../script/config.json')

// Create a web3 instance
// const web3 = new Web3(new Web3.providers.HttpProvider("HTTP://172.31.100.218:7545"));
const web3 = new Web3(new Web3.providers.HttpProvider(data.web3ProviderUrl));

// const contractAddress = "0x1C62050BBb30CdbfcE0149dc95313094Ea993234";
const contractAddress = data.contractAddress;

// Load Contract ABI
const sonyAbi = require("../script/sony.json");

// const savedPrivateKey = localStorage.getItem("PrivateKey");
const PrivateKey = localStorage.getItem("PrivateKey");

// alert('p: ' + PrivateKey)

class ClientWebSocket {
  constructor() {
    this.socket = null;
  }

  async sendMessageToAP(ip, port, message) {
    return new Promise((resolve, reject) => {
      const address = `ws://${ip}:${port}`;

      if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
        // Close the existing connection before opening a new one
        if (this.socket) {
          this.socket.onclose = null;
          this.socket.close();
        }

        console.log("Establishing a new connection");
        this.socket = new WebSocket(address);

        // Set up event handlers once when the connection is established
        this.socket.onopen = function () {
          this.socket.send(message);
        }.bind(this);

        this.socket.onmessage = function (event) {
          const validationResult = event.data;
          console.log("Received message from server:", validationResult);
          resolve(validationResult);
        }.bind(this);

        this.socket.onerror = function (error) {
          console.error("WebSocket error:", error);
          reject(new Error("WebSocket error"));
        }.bind(this);

        this.socket.onclose = function (event) {
          console.log("WebSocket connection closed:", event);
          reject(new Error("WebSocket connection closed"));
        }.bind(this);
      } else {
        // If the connection is open, simply send the message
        this.socket.send(message);
        this.socket.onmessage = function (event) {
          const validationResult = event.data;
          console.log("Received message from server:", validationResult);
          resolve(validationResult);
        }.bind(this);

        this.socket.onerror = function (error) {
          console.error("WebSocket error:", error);
          reject(new Error("WebSocket error"));
        }.bind(this);

        this.socket.onclose = function (event) {
          console.log("WebSocket connection closed:", event);
          reject(new Error("WebSocket connection closed"));
        }.bind(this);
      }
    });
  }

  async tryConnect(tokenId) {
    const authenticationRequestFlag = "requestValidation";
    try {
      const sendAuthenticationRequest = {
        authenticationRequest: authenticationRequestFlag,
      };

      const sendAuthenticationRequestMessage = JSON.stringify(sendAuthenticationRequest);
      const validationRandomNumber = await this.sendMessageToAP(IpAddress, 9999, sendAuthenticationRequestMessage);

      // const signatureResult = web3.eth.accounts.sign(String(validationRandomNumber), savedPrivateKey).signature;
      const signatureResult = web3.eth.accounts.sign(String(validationRandomNumber), PrivateKey).signature;

      const sendData = {
        tokenId: tokenId,
        signatureResult: signatureResult,
      };

      const sendSignatureMessage = JSON.stringify(sendData);

      return await this.sendMessageToAP(IpAddress, 9999, sendSignatureMessage)
    } catch (error) {
      console.error("WebSocket error:", error);

      const Toast = Swal.mixin({
        toast: true,
        position: "top",
        showConfirmButton: false,
        timer: 1500,
        timerProgressBar: false,
        didOpen: (toast) => {
          toast.onmouseenter = Swal.stopTimer;
          toast.onmouseleave = Swal.resumeTimer;
        }
      });
      Toast.fire({
        icon: "error",
        title: "Connection to server failed, please try again!"
      });
      return false
    }
  }
}

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

      isConnecting: false,

      isTransferring: false,

      // Countdown time
      Countdown: "",

      TotalNFTGroup: [],

      // Ethereum address
      Address: "",

      // An array composed of valid NFTs
      UnexpiredNFT: [],

      allNFTNumber: 0,

      // The number of valid NFTs
      UnexpiredNFTNumber: 0,

      AP_IDs: [],

      // An array composed of invalid NFTs
      ExpiredNFT: [],

      expirationTimeList: [],
      NFTtoAPMapping: {},

      // Number of invalid NFTs
      ExpiredNFTNumber: 0,

      // AccountBalance
      AccountBalance: 0,

      NoNFT: false,

      formLabelWidth: "55px",

      Reload: '',

      ValidationResult: '',
    };
  },

  methods: {
    PurchaseNFT() {
      this.$router.push('/NFTStore')
    },

    AuctionNFT() {
      this.$router.push('/AuctionInfo')
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
      if (this.AccountBalance <= amount) {
        this.showError("Your balance is insufficient");
        return;
      }
      try {
        this.transferFlag = false;
        this.isTransferring = true;
        const txCount = await web3.eth.getTransactionCount(this.Address);
        const txObject = {
          nonce: txCount,
          to: toAddress,
          value: web3.utils.toWei(amount, 'ether'),
          gasLimit: 3000000,
          gasPrice: web3.utils.toWei('3', 'gwei'),
        };
        // const signed = await web3.eth.accounts.signTransaction(txObject, savedPrivateKey);
        const signed = await web3.eth.accounts.signTransaction(txObject, PrivateKey);
        await web3.eth.sendSignedTransaction(signed.rawTransaction);
        this.AccountBalance = await this.getBalance(this.Address);
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

    async connectionConfirmation(tokenId) {
      try {
        Swal.fire({
          text: "Are you sure you want to connect?",
          icon: "question",
          showCancelButton: true,
          confirmButtonColor: "#3085d6",
          cancelButtonColor: "orange",
          confirmButtonText: "Confirm"
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.isConnecting = true;
            setTimeout(this.CloseLoadingIcon, 8000)
            const webSocketInstance = new ClientWebSocket();
            const validationResult = await webSocketInstance.tryConnect(Number(tokenId))
            this.ValidationResult = validationResult

            if (validationResult === "True") {
              this.Countdown = await this.contractInstance.methods.getRemainingUsageTime(tokenId).call();
              window.sessionStorage.removeItem("Countdown");
              window.sessionStorage.setItem("Countdown", this.Countdown);
             this.isConnecting = false;
              Swal.fire({
                position: "center",
                icon: "success",
                title: "Verification successful!",
                showConfirmButton: false,
                timer: 1500
              });
              setTimeout(() => {
                this.$router.push('/ConnectSuccess')
              }, 1500);
            } else {
              this.isConnecting = false;
              const Toast = Swal.mixin({
                toast: true,
                position: "top",
                showConfirmButton: false,
                timer: 1500,
                timerProgressBar: false,
                didOpen: (toast) => {
                  toast.onmouseenter = Swal.stopTimer;
                  toast.onmouseleave = Swal.resumeTimer;
                }
              });
              Toast.fire({
                icon: "error",
                title: "Verification exception, connection failed!"
              });
            }
          } else {
            console.info("User canceled verification")
          }
        });
      } catch (error) {
        return null
      }
    },

    CloseLoadingIcon() {
      console.log(this.ValidationResult)
      if (this.ValidationResult === "True") {
        return null
      } else if (this.ValidationResult === '') {
        this.isConnecting = false
        const Toast = Swal.mixin({
          toast: true,
          position: "top",
          showConfirmButton: false,
          timer: 1500,
          timerProgressBar: false,
          didOpen: (toast) => {
            toast.onmouseenter = Swal.stopTimer;
            toast.onmouseleave = Swal.resumeTimer;
          }
        });
        Toast.fire({
          icon: "error",
          title: "Verification timeout, please try again!"
        });
      }
    },

    async getOwnedAllNFT(address) {
      const result = await this.contractInstance.methods.getOwnedNFTs(address).call()
      // console.log("result:" + result)
      if (result && typeof result === 'object') {
        // Directly access data by attribute name
        this.TotalNFTGroup = result[0];
        // console.log(this.TotalNFTGroup.length)
        this.allNFTNumber = this.TotalNFTGroup.length;
        // this.PriceGroup = result[1].map(wei => web3.utils.fromWei(wei, 'ether'));
        this.AP_IDs = result[2];
        for (let i = 0; i < this.TotalNFTGroup.length; i++) {
          this.NFTtoAPMapping[this.TotalNFTGroup[i]] = this.AP_IDs[i];
        }
        this.expirationTimeList = result[3];
        // console.log(this.expirationTimeList)
        this.UnexpiredNFT = result[4];
        this.UnexpiredNFTNumber = this.UnexpiredNFT.length;
        this.ExpiredNFT = result[5];
        this.ExpiredNFTNumber = this.ExpiredNFT.length;
        if (this.allNFTNumber === 0) {
          this.NoNFT = true;
        }
      } else {
        console.error("Invalid result structure:", result);
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
    // this.Address = web3.eth.accounts.privateKeyToAccount(savedPrivateKey).address;
    this.Address = web3.eth.accounts.privateKeyToAccount(PrivateKey).address;

    try {
      this.contractInstance = await this.createContractInstance(sonyAbi, contractAddress);

      await this.getOwnedAllNFT(this.Address);
      this.AccountBalance = this.getBalance(this.Address)
          .then((balance) => {
            this.AccountBalance = balance;
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

#ExpiredNFT {
  font-size: 18px;
  font-weight: bold;
}

#ExpiredNFTNumber {
  width: 300px;
  height: 60px;
  margin: 10px;
  padding: 5px;
  font-size: 15px;
  text-align: center;
  border: transparent;
  background-color: white;
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
  content: url('../assets/WiFi.svg');
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

.btn1 {
  position: relative;
  width: 300px;
  height: 85px;
  background-color: rgb(107, 108, 107);
  font-size: 18px;
  color: white;
  border: rgb(74, 148, 232);
  border-radius: 20px;
  text-align: center;
  z-index: 1;
}

.btn1:after {
  content: url('../assets/no-WiFi.svg');
  position: absolute;
  top: 3px;
  right: 5px;
  z-index: 1;
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
#wifi-loader {
  --background: #62abff;
  --front-color: #4f29f0;
  --back-color: #c3c8de;
  --text-color: #414856;
  width: 64px;
  height: 64px;
  border-radius: 50px;
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
}

#wifi-loader svg {
  position: absolute;
  display: flex;
  justify-content: center;
  align-items: center;
}

#wifi-loader svg circle {
  position: absolute;
  fill: none;
  stroke-width: 6px;
  stroke-linecap: round;
  stroke-linejoin: round;
  transform: rotate(-100deg);
  transform-origin: center;
}

#wifi-loader svg circle.back {
  stroke: var(--back-color);
}

#wifi-loader svg circle.front {
  stroke: var(--front-color);
}

#wifi-loader svg.circle-outer {
  height: 86px;
  width: 86px;
}

#wifi-loader svg.circle-outer circle {
  stroke-dasharray: 62.75 188.25;
}

#wifi-loader svg.circle-outer circle.back {
  animation: circle-outer135 1.8s ease infinite 0.3s;
}

#wifi-loader svg.circle-outer circle.front {
  animation: circle-outer135 1.8s ease infinite 0.15s;
}

#wifi-loader svg.circle-middle {
  height: 60px;
  width: 60px;
}

#wifi-loader svg.circle-middle circle {
  stroke-dasharray: 42.5 127.5;
}

#wifi-loader svg.circle-middle circle.back {
  animation: circle-middle6123 1.8s ease infinite 0.25s;
}

#wifi-loader svg.circle-middle circle.front {
  animation: circle-middle6123 1.8s ease infinite 0.1s;
}

#wifi-loader svg.circle-inner {
  height: 34px;
  width: 34px;
}

#wifi-loader svg.circle-inner circle {
  stroke-dasharray: 22 66;
}

#wifi-loader svg.circle-inner circle.back {
  animation: circle-inner162 1.8s ease infinite 0.2s;
}

#wifi-loader svg.circle-inner circle.front {
  animation: circle-inner162 1.8s ease infinite 0.05s;
}

#wifi-loader .wifi-loader-text {
  position: absolute;
  bottom: -40px;
  display: flex;
  justify-content: center;
  align-items: center;
  text-transform: lowercase;
  font-weight: 500;
  font-size: 20px;
  letter-spacing: 0;
}

#wifi-loader .wifi-loader-text::before, #wifi-loader .wifi-loader-text::after {
  content: attr(data-text);
}

#wifi-loader .wifi-loader-text::before {
  color: var(--text-color);
}

#wifi-loader .wifi-loader-text::after {
  color: var(--front-color);
  animation: text-animation76 3.6s ease infinite;
  position: absolute;
  left: 0;
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
