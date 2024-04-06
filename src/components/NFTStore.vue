<template>
  <div id="app">
    <div id="head">
      <h1>WiFi-NFT Store</h1>

      <p class="text">Your Balance:  {{
          AccountBalance !== 0 ? Math.floor(AccountBalance * 1000000) / 1000000
              : AccountBalance
        }} ETH</p>

    </div>

    <br/>
    <br/>

    <div class="purchase-container">
      <div class="purchase-info">
        <div v-if="onSellNFTGroupLength === 0" class="no-purchase-nft-message">
          <p>There are currently no NFTs for sale!</p>
        </div>
        <div class="purchase-item" v-for="(item, index) in onSellNFTGroup" :key="index">
          <div class="item-header">
            <br/>
            <h2>Token ID: {{ item }}</h2>
            <p>AP ID: {{ AP_IDGroup[index] }}</p>
          </div>

          <div class="item-details">
            <br/>
            <p v-if="this.TimeArray_Day[index] === 0">
              NFT Duration: {{ TimeArray_Hour[index] }}H
            </p>
            <p v-else-if="this.TimeArray_Hour[index] === 0">
              NFT Duration: {{ TimeArray_Day[index] }}D
            </p>
            <p v-else>
              NFT Duration: {{ TimeArray_Day[index] }}D {{ TimeArray_Hour[index] }}h
            </p>

            <p>Price: {{ PriceGroup[index] }}ETH</p>
          </div>

          <div class="purchase-buttons">
            <button
                v-if="this.Role==='user' && this.AccountBalance > this.PriceGroup[index]"
                name="PurchaseButton"
                class="PurchaseButton" :key="index + 1"
                v-on:click="purchaseConfirmation(index)">
              Purchase
            </button>

            <button
                v-else-if="this.Role==='user' && this.AccountBalance < this.PriceGroup[index]"
                name="PurchaseButton"
                class="PurchaseButtonDisable" :key="index + 1"
                v-on:click="purchaseConfirmation(index)"
                disabled>
              Purchase
            </button>

            <button
                v-else
                name="PurchaseButton"
                class="PurchaseButtonDisable" :key="index"
                v-on:click="purchaseConfirmation(index)"
                disabled>
              Purchase
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="transactionProcessing" class="transactionProcessing-overlay">
      <div class="transactionProcessing-icon">
        <img src="../assets/transaction-processing-icon.svg" alt="Transaction in progress...">
      </div>

      <div class="transactionProcessing-text">
        Transaction is being processed, please wait...
      </div>
    </div>

    <div id="foot">
      <br/>

      <div class="button-container">
        <button @click="Back()" class="go-back-button">Go Back</button>
      </div>
    </div>

  </div>
</template>

<script>
import Swal from "sweetalert2";

import Web3 from "web3";

const data = require('../script/config.json')

// const web3 = new Web3(new Web3.providers.HttpProvider("HTTP://172.31.100.218:7545"));
const web3 = new Web3(new Web3.providers.HttpProvider(data.web3ProviderUrl));

// const contractAddress = "0x1C62050BBb30CdbfcE0149dc95313094Ea993234";
const contractAddress = data.contractAddress;

const sonyAbi = require("../script/sony.json");

export default {
  name: 'NFTPurchase',

  props: {
    msg: String
  },

  data() {
    return {
      // The variables in data are responsive data used to store the internal state of components.
      // Enable synchronization between data and views
      onSellNFTGroup: [],

      // showFinishedAnimation: false,
      onSellNFTGroupLength: 0,

      //unit: eth
      PriceGroup: [],

      AP_IDGroup: [],

      Address: "",

      AccountBalance: null,

      EffectiveTime: "",

      durationGroup: [],

      NFTPrice: "",

      TokenID: "",

      transactionProcessing: false,

      Role: localStorage.getItem("Role"),

      savedPrivateKey: '',

      TimeArray_Day: [],

      TimeArray_Hour: [],
    };
  },

  async mounted() {
    this.JudgeIdentity();

    try {
      this.contractInstance = await this.createContractInstance(sonyAbi, contractAddress);
      // Check if PrivateKey and AccountBalance exist in LocalStorage
      if (!this.savedPrivateKey) {
        console.error("Private key not found in localStorage");
        return;
      }
      this.Address = web3.eth.accounts.privateKeyToAccount(this.savedPrivateKey).address;
      this.AccountBalance = web3.utils.fromWei(await web3.eth.getBalance(this.Address), 'ether');
      // Using await to call the getAvailableNFTsInfo method
      const result = await this.contractInstance.methods.getAvailableNFTsInfo().call();

      if (result && typeof result === 'object') {
        // Directly access data by attribute name
        this.onSellNFTGroup = result[0];
        this.onSellNFTGroupLength = this.onSellNFTGroup.length;
        this.PriceGroup = result[1].map(wei => web3.utils.fromWei(wei, 'ether'));
        this.AP_IDGroup = result[2];
        this.durationGroup = result[3];
      } else {
        console.error("Invalid result structure:", result);
      }
    } catch (error) {
      console.error("Error in mounted:", error);
    }

    this.DurationTime()
  },

  methods: {
    DurationTime() {
      for(let i = 0; i < this.durationGroup.length; i++) {
        const DurationTime = Number(this.durationGroup[i]);

        const DurationTime_Day = Math.trunc(DurationTime / 86400)
        const DurationTime_Hour = (DurationTime - DurationTime_Day * 86400) / 3600

        const TimeArray_Day = this.TimeArray_Day
        const TimeArray_Hour = this.TimeArray_Hour

        TimeArray_Day.push(DurationTime_Day)
        TimeArray_Hour.push(DurationTime_Hour)
      }
    },

    Reload() {
      window.location.reload()
    },

    JudgeIdentity() {
      if(this.Role === 'user') {
        this.savedPrivateKey = localStorage.getItem('PrivateKey')
      }
      else if (this.Role === 'admin') {
        this.savedPrivateKey = localStorage.getItem('AdministratorPrivateKey')
      }
    },

    Back() {
      if(this.Role === 'user') {
        this.$router.push('/UserInterface')
      }
      else {
        this.$router.push('/AdminInterface')
      }
    },

    BackToAccountDetailsPage() {
      this.$router.push('/UserInterface')
    },

    async createContractInstance(abi, contractAddress) {
      return new Promise((resolve) => {
        const contractInstance = new web3.eth.Contract(abi, contractAddress);
        resolve(contractInstance);
      });
    },

    async buyNFT(tokenId, price) {
      try {
        this.transactionProcessing = true;
        const balance = Number(await this.contractInstance.methods.balanceOf(this.Address, tokenId).call());
        const noNFT = balance === 0;

        if (noNFT) {
          const txCount = await web3.eth.getTransactionCount(this.Address);
          const purchaseInstance = this.contractInstance.methods.purchaseNFT(tokenId)
          const purchaseInstanceEncodedABI = purchaseInstance.encodeABI();
          const txObject = {
            nonce: txCount,
            to: contractAddress,
            value: web3.utils.toWei(price, 'ether'),
            gasLimit: 3000000,
            gasPrice: web3.utils.toWei('2', 'gwei'),
            data: purchaseInstanceEncodedABI
          };

          const signed = await web3.eth.accounts.signTransaction(txObject, this.savedPrivateKey);
          await web3.eth.sendSignedTransaction(signed.rawTransaction);



          // Update available NFT data for purchase
          const result = await this.contractInstance.methods.getAvailableNFTsInfo().call();

          if (result && typeof result === 'object') {
            // Directly access data by attribute name
            this.onSellNFTGroup = result[0];
            this.onSellNFTGroupLength = this.onSellNFTGroup.length;
            this.PriceGroup = result[1].map(wei => web3.utils.fromWei(wei, 'ether'));
            this.AP_IDGroup = result[2];
            this.durationGroup = result[3];
          } else {
            console.error("Invalid result structure:", result);
          }
          this.transactionProcessing = false;
          const Toast = Swal.mixin({
            toast: true,
            position: "top",
            showConfirmButton: false,
            timer: 2000,
            timerProgressBar: false,
            didOpen: (toast) => {
              toast.onmouseenter = Swal.stopTimer;
              toast.onmouseleave = Swal.resumeTimer;
            }
          });
          Toast.fire({
            icon: "success",
            title: "Purchase successful, please go to your wallet to check!"
          });
        } else {
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
            title: "You already own the NFT and do not need to purchase it. " +
                "Please go to the wallet details to check!"
          });
        }
        window.setTimeout(this.Reload, 1600)
      } catch (error) {
        // error handling
        console.error("Error:", error.message);
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
          title: "Transaction failed, please try again! Error message: " + error.message
        });
      } finally {
        //update AccountBalance
        this.AccountBalance = web3.utils.fromWei(await web3.eth.getBalance(this.Address), 'ether');
        this.transactionProcessing = false;
      }
    },

    async purchaseConfirmation(index) {
      try {
        const tokenId = this.onSellNFTGroup[index];
        const price = this.PriceGroup[index];
        const AP_ID = this.AP_IDGroup[index];
        const duration = this.durationGroup[index];
        const userConfirmed = await
            Swal.fire({
              text: "Are you sure you want to purchase this wifi NFT with ID " + tokenId + "," +
                  "price " + price + "ETH" + "," + "AP ID " + AP_ID + "," + "and available duration " + duration + "s?",
              icon: "warning",
              showCancelButton: true,
              confirmButtonColor: "#3085d6",
              cancelButtonColor: "orange",
              confirmButtonText: "Confirm"
            }).then((result) => {
              if (result.isConfirmed) {
                this.buyNFT(tokenId, price);
              }
              else {
                console.info("User canceled verification")
              }
            });
      } catch (error) {
        return null
      }
    },
  }
};
</script>

<style scoped>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

#head {
  width: 100%;
  text-align: center;
  position: fixed;
  top: 0;
  left: -3px;
  right: 0;
  background-color: white;
}

p {
  word-break: break-all;
}

.text {
  text-align: center;
  font-size: 15px;
}

hr {
  text-align: center;
  width: 340px;
}

.transactionProcessing-overlay {
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

.transactionProcessing-icon img {
  width: 100px;
  height: 100px;
}

.transactionProcessing-text {
  color: #329f32;
  font-size: 20px;
  margin-top: 10px;
}

#foot {
  position: relative;
  top: 10px;
  left: 0;
  margin-bottom: 20px;
  width: 100%;
  text-align: center;
}

.go-back-button {
  width: 200px;
  background-color: #4CAF50; /* Green */
  border: none;
  color: white;
  padding: 15px 0;
  text-align: center;
  text-decoration: none;
  font-size: 16px;
  margin: 0 auto;
  cursor: pointer;
  border-radius: 8px;
  transition: background-color 0.3s ease;
}

.button-container {
  display: block;
}

.go-back-button:hover {
  background-color: #45a049; /* Darker Green */
}

.go-back-button:active {
  transform: scale(0.96);
}

.purchase-item {
  border-radius: 10px; /* Rounded edges */
  padding: 20px;
  margin: 35px; /* Add margin to separate cards and remove the gap */
  background-color: #f3f4f6; /* Light gray background */
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); /* Slight shadow */
  /*flex-grow: 0; !* Make each card grow to fill available space *!*/
  min-width: 300px; /* Set minimum width for each card */
  flex: 0 0 calc(25% - 10px); /* 设置每个卡片的宽度，考虑到间距 */
  /*margin: 5px; !* 设置卡片间距 *!*/
}

.purchase-buttons {
  display: flex;
  justify-content: space-between; /* Evenly distribute buttons */
  margin-top: 10px; /* Add some spacing between buttons and details */
}

.purchase-buttons button {
  flex: 1; /* Make buttons equally distribute available space */
  margin: 0 5px; /* Add margin to separate buttons */
  padding: 10px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s ease;
}

.purchase-buttons button:hover {
  background-color: #4a90e2; /* Darker shade of blue on hover */
  color: #ffffff; /* White text on hover */
}

.purchase-buttons button:active {
  transform: scale(0.96);
}

.PurchaseButton {
  background-color: #b8e994; /* Light green */
}

.PurchaseButtonDisable {
  color: white;
  background-color: gray; /* Light green */
  pointer-events: none;
}

.purchase-container {
  margin-top: 10px;
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
}

.item-header {
  background: #99bad5; /* Blue background */
  border-radius: 10px;
  padding-bottom: 10px;
}

.item-header h3 {
  margin: 0;
  font-size: 18px;
  text-align: center;
  color: black;
}

.item-details {
  margin-top: 10px;
  border-radius: 10px;
  padding-bottom: 10px;
  text-align: center;
  background: #d2eed2;
}

.item-details p {
  margin: 5px 0;
  font-size: 16px;
  color: black; /* Dark gray text */
}

@media screen and (max-width: 768px) {
  .purchase-item,
  .go-back-button {
    width: calc(50% - 40px); /* Set width to 50% for screens smaller than 768px */
  }
}

@media screen and (max-width: 480px) {
  .purchase-item,
  .go-back-button {
    width: calc(100% - 40px); /* Set width to 100% for screens smaller than 480px */
  }
}

.no-purchase-nft-message {
  text-align: center; /* 居中文本 */
  margin-top: 50px; /* 添加一些顶部间距 */
  padding: 20px; /* 添加一些内边距 */
  background-color: #f5dcdc; /* 背景颜色 */
  border-radius: 8px; /* 圆角边框 */
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); /* 阴影效果 */
  font-size: 20px;
}

.purchase-info {
  display: flex;
  flex-wrap: wrap;
  justify-content: center; /* Center items horizontally */
}
</style>