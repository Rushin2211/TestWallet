<template>
  <div id="app">
    <div id="head">
      <h1>Admin Area</h1>

      <p class="text">Address : {{ accountAddress }}</p>

      <p v-if="isLoading" class="balanceLoading">Loading Account Balance...</p>

      <p v-else class="text">Account Balance: {{
          accountBalance !== 0 ? Math.floor(accountBalance * 1000000) / 1000000
              : accountBalance
        }} ETH</p>

      <p class="text">Total NFT : {{ ownedNFTNumber }}</p>
      <hr/>
    </div>

    <br/>
    <br/>
    <br/>
    <br/>
    <br/>
    <br/>
    <br/>

    <p v-for="(item, index) in ownedNFTGroup" :key="item">
      <button name="NFTButton"
              class="NFTButton"
              :class="{
        'NFTsOnAuctionButton':currentAuctionNFTs.includes(ownedNFTGroup[index]) }"
              :key="index">
        <small class="BtnTitle">NFT{{ index + 1 }}</small>
        <br/>
        <small class="BtnText">Token ID:{{ item }}</small>
      </button>
    </p>

    <div v-if="isTransferring " class="loading-overlay">
      <div class="loading-icon">
        <img src="../assets/transaction-processing-icon.svg" alt="Loading">
      </div>
      <div class="loading-text">
        Transferring, please wait...
      </div>
    </div>

    <div v-if="isMinting" class="loading-overlay">
      <div class="loading-icon">
        <img src="../assets/minting-icon.svg" alt="Loading">
      </div>
      <div class="loading-text">Minting, please wait...</div>
    </div>

    <div v-if="isAuction" class="loading-overlay">
      <div class="loading-icon">
        <img src="../assets/selling-icon.svg" alt="Loading">
      </div>
      <div class="loading-text">For auction, please wait...</div>
    </div>

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

    <el-dialog title="Auction NFT" v-model="auctionFlag" width="380px" style="margin-top: 50px">
      <p style="text-align: center; margin: 10px 0;">Please select an NFT you want to auction:</p>

      <div style="display: flex; flex-wrap: wrap;">
        <div v-for="item in availableForAuctionGroup" :key="item" style="width: 33%; display: flex; align-items:
        center; margin-bottom: 10px;">
          <el-radio v-model="selectedNFTForAuction" :label="item" style="width: 100%;">Token ID:{{ item }}</el-radio>
        </div>
      </div>

      <el-form :model="AuctionNFTFrom" label-width="80px" style="margin-top: 20px;">
        <el-form-item label="Duration">
          <el-col :span="11">
            <el-input
                style="width: 100%;"
                v-model="AuctionNFTFrom.biddingTimeDay"
                placeholder="Day  (Auction)"
                autocomplete="off">
            </el-input>
          </el-col>

          <el-col class="line" :span="1">-</el-col>

          <el-col :span="11">
            <el-input
                style="width: 100%;"
                v-model="AuctionNFTFrom.biddingTimeHour"
                placeholder="Hour  (Auction)"
                autocomplete="off">
            </el-input>
          </el-col>
        </el-form-item>
        <el-form-item label="Beneficiary">
          <el-input v-model="AuctionNFTFrom.beneficiary" autocomplete="off"
                    placeholder="beneficiary address" style="width: 250px"></el-input>
        </el-form-item>
        <el-form-item label="Price">
          <el-input v-model="AuctionNFTFrom.bottomPrice" autocomplete="off"
                    placeholder="starting price (uint:ETH)" style="width: 250px"></el-input>
        </el-form-item>
      </el-form>

      <div style="text-align: center; margin-top: 20px;">
        <el-button @click="Cancel" style="margin-right: 20px; font-size: 16px;">Cancel</el-button>
        <el-button type="primary" @click="submitInventoryForAuction" style="font-size: 16px; padding: 12px 20px;">
          Confirm
        </el-button>
      </div>
    </el-dialog>

    <div id="foot">
      <hr/>
      <button name="Transfer Ethereum" class="btn" v-on:click="transfer">Transfer</button>
      <br/>
      <br/>
      <button name="MintNFT" class="btn" @click="mintWiFiNFT">Mint NFTs</button>
      <br/>
      <br/>
      <button name="AuctionNFT" class="btn" @click="confirmAuctionNFT">Auction</button>
      <br/>
      <br/>
      <button name="AuctionInfo" class="btn" @click="goToAuctionInfoPage">Auction Info</button>
      <br/>
      <br/>
      <button name="Exit" class="btn" v-on:click="Exit">Exit</button>
      <br/>
    </div>

  </div>
</template>

<script>
import Swal from "sweetalert2";
import Web3 from "web3";
import {isAddress} from "web3-validator";

const data = require('../script/config.json')

const web3 = new Web3(new Web3.providers.HttpProvider(data.web3ProviderUrl));

const contractAddress = data.contractAddress;

// todo
const contractAbi = require("../script/sony.json");

const savedAdminPrivateKey = localStorage.getItem("AdministratorPrivateKey");

export default {
  name: 'AdminInterface',

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

      isTransferring: false,

      accountAddress: '',

      isLoading: true,

      accountBalance: '',

      contractInstance:'',

      ownedNFTGroup: [],

      ownedNFTNumber: '',

      isMinting: false,

      isAuction: false,

      auctionFlag: false,

      AuctionNFTFrom: {
        biddingTimeDay: null,
        biddingTimeHour: null,
        beneficiary: null,
        bottomPrice: null,
      },

      availableForAuctionGroup: [],

      NFTAuctionEndTime: [],

      currentAuctionNFTs: [],

      selectedNFTForAuction: null,

      formLabelWidth: "55px",
    };
  },

  created() {
    this.AdminHasRefreshed()
  },

  async mounted() {
    this.accountAddress = web3.eth.accounts.privateKeyToAccount(savedAdminPrivateKey).address;
    this.contractInstance = await this.createContractInstance(contractAbi, contractAddress);
    this.accountBalance = await this.getBalance(this.accountAddress);
    await this.getOwnedAllNFT(this.accountAddress);
    let currentTime = new Date().getTime() / 1000
    for (let i = 0; i < this.NFTAuctionEndTime.length; i++) {
      if (this.NFTAuctionEndTime[i] < currentTime && Number(this.NFTAuctionEndTime[i]) !== 0) {
        Swal.fire({
          html: "You have an ongoing auction that needs to be concluded. " +
              "Please visit the <strong>Auction Info </strong>page to end it.",
          icon: "info",
          showCloseButton: true,
          showCancelButton: false,
          focusConfirm: true,
          confirmButtonText: "OK",
        });
        break
      }
    }
  },

  methods: {
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
        const signed = await web3.eth.accounts.signTransaction(txObject, savedAdminPrivateKey);
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

    DayToSecond(Day) {
      this.durationDayValue = Number(Day);
      if(this.durationDayValue.toString().indexOf(".") !== -1) {
        this.DurationDay_float = true
      }
      if (this.durationDayValue === ''){
        this.durationDayValue = '0'
      }
    },

    HourToSecond(Hour) {
      this.durationHourValue = Number(Hour);
      if(this.durationHourValue.toString().indexOf(".") !== -1) {
        this.DurationHour_float = true
      }
      if (this.durationHourValue === ''){
        this.durationHourValue = '0'
      }
    },

    TimeConversion(Day, Hour) {
      this.DayToSecond(Day);
      this.HourToSecond(Hour);
      return this.durationDayValue * 86400 + this.durationHourValue * 3600;
    },

    async createContractInstance(abi, contractAddress) {
      return new Promise((resolve) => {
        const contractInstance = new web3.eth.Contract(abi, contractAddress);
        resolve(contractInstance);
      });
    },

    isPositiveInteger(num) {
      // Using regular expressions to check for positive integers
      return /^[1-9]\d*$/.test(num);
    },

    async mintWiFiNFT() {
      try {
        this.isMinting = true;
        const txCount = await web3.eth.getTransactionCount(this.accountAddress);
        const mintInstance = this.contractInstance.methods.mintERC721Token(this.accountAddress);
        const mintInstanceEncodedABI = mintInstance.encodeABI();
        const txObject = {
          nonce: txCount,
          to: contractAddress,
          gasLimit: 3000000,
          gasPrice: web3.utils.toWei('2', 'gwei'),
          data: mintInstanceEncodedABI
        };
        const signed = await web3.eth.accounts.signTransaction(txObject, savedAdminPrivateKey);
        await web3.eth.sendSignedTransaction(signed.rawTransaction);
        this.isMinting = false;
        await this.getOwnedAllNFT(this.accountAddress);
        Swal.fire({
          position: "center",
          icon: "success",
          title: "NFTs minted successfully!",
          showConfirmButton: false,
          timer: 2500
        });
        // setTimeout(this.Reload, 1100);
      } catch (error) {
        this.isMinting = false;
        this.showError(`Transaction failed: ${error.message}`);
      }
    },

    //提交拍卖数据表单
    async submitInventoryForAuction() {
      const tokenId = this.selectedNFTForAuction;
      const biddingTimeDay = this.AuctionNFTFrom.biddingTimeDay;
      const biddingTimeHour = this.AuctionNFTFrom.biddingTimeHour;
      const biddingTime = this.TimeConversion(biddingTimeDay, biddingTimeHour);
      const beneficiary = this.AuctionNFTFrom.beneficiary;
      const bottomPrice = this.AuctionNFTFrom.bottomPrice;

      if(this.selectedNFTForAuction === null) {
        this.showError("Please select the NFT you want to auction");
        return
      }

      if (!(
          this.AuctionNFTFrom.biddingTimeDay >= 0 &&
          this.AuctionNFTFrom.biddingTimeHour >= 0
      )) {
        this.showError("Duration must be a positive integer");
        return;
      }

      if (
          this.AuctionNFTFrom.biddingTimeDay == null &&
          this.AuctionNFTFrom.biddingTimeHour === null
      ) {
        this.showError("Duration cannot be null");
        return
      }

      if (beneficiary == null) {
        this.showError("beneficiary cannot be null");
        return
      }

      if (!isAddress(beneficiary)) {
        this.showError("Beneficiary address format is wrong");
        return
      }

      if (!(bottomPrice > 0)) {
        this.showError("Bottom price must be a positive integer");
        return;
      }

      if (bottomPrice === null) {
        this.showError("Bottom price cannot be null");
        return
      }

      try {
        this.auctionFlag = false;
        this.isAuction = true;
        const txCount = await web3.eth.getTransactionCount(this.accountAddress);
        const auctionInstance = this.contractInstance.methods.startAuction(
            tokenId,
            biddingTime,
            beneficiary,
            bottomPrice
        );
        const auctionInstanceABI = auctionInstance.encodeABI();
        const txObject = {
          nonce: txCount,
          to: contractAddress,
          gasLimit: 3000000,
          gasPrice: web3.utils.toWei("2", "gwei"),
          data: auctionInstanceABI
        }
        const signed = await web3.eth.accounts.signTransaction(txObject, savedAdminPrivateKey);
        await web3.eth.sendSignedTransaction(signed.rawTransaction);
        await this.getOwnedAllNFT(this.accountAddress);
        this.Cancel();
        this.isAuction = false;
        Swal.fire({
          position: "center",
          icon: "success",
          title: "The NFT you selected is currently being auctioned!",
          showConfirmButton: false,
          timer: 2500
        });
        // setTimeout(this.Reload, 1100);
      } catch (error) {
        this.isAuction = false;
        this.Cancel();
        this.showError(`Transaction failed: ${error.message}`);
      }
    },

    showError(message) {
      this.$message.error({
        duration: 1500,
        message,
        offset: 50,
      });
    },

    confirmAuctionNFT() {
      this.auctionFlag = true;
      this.selectedNFTForAuction = null;
      this.AuctionNFTFrom.biddingTimeDay = null;
      this.AuctionNFTFrom.biddingTimeHour = null;
      this.AuctionNFTFrom.beneficiary = this.accountAddress;
      this.AuctionNFTFrom.bottomPrice = null;
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

    async getOwnedAllNFT(address) {
      this.availableForAuctionGroup.length = 0;
      this.NFTAuctionEndTime.length = 0;

      this.ownedNFTGroup = await this.contractInstance.methods.getAccountNFTInfo(address).call();
      console.log(this.ownedNFTGroup);
      this.ownedNFTNumber = this.ownedNFTGroup.length;

      for (let i = 0; i < this.ownedNFTNumber; i++){
        const nftAuctionInfo = await this.contractInstance.methods.nftAuctionInfo(this.ownedNFTGroup[i]).call();

        const auctionEndTime = nftAuctionInfo[1]
        this.NFTAuctionEndTime.push(auctionEndTime);

        if (nftAuctionInfo[5] === false) {
          console.log(i)
          this.availableForAuctionGroup.push(this.ownedNFTGroup[i]);
        }
      }
      console.log(this.availableForAuctionGroup);
      this.currentAuctionNFTs = await this.contractInstance.methods.getAuctionNFTList().call();
      console.log(this.currentAuctionNFTs);
    },

    Cancel() {
      this.transferFlag = false;
      this.auctionFlag = false;
    },

    Exit() {
      setTimeout(this.BackToLoginPage, 300)
    },

    BackToLoginPage() {
      this.$router.push('/LogIn')
    },

    goToAuctionInfoPage() {
      this.$router.push('/TestPage1');
    },

    AdminHasRefreshed() {
      const AdminHasRefreshed = localStorage.getItem('AdminHasRefreshed');

      if (!AdminHasRefreshed) {
        this.Reload();
        localStorage.setItem('AdminHasRefreshed', 'true');
      } else {
        localStorage.removeItem('AdminHasRefreshed');
      }
    },

    Reload() {
      window.location.reload();
    }
  }
}
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

p {
  word-break: break-all;
}

#head {
  width: 100%;
  height: 200px;
  text-align: center;
  position: fixed;
  top: -10px;
  left: -1px;
  background-color: white;
  z-index: 1;
}

.text {
  font-size: 13px;
}

hr {
  width: 350px;
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

.btn {
  width: 250px;
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
  width: 100px;
  height: 100px;
}

.loading-text {
  color: #329f32;
  font-size: 20px;
  margin-top: 10px;
}

.balanceLoading {
  font-size: 15px;
  color: #24a962;
}

.BtnTitle {
  font-size: 20px !important;
}

.BtnText {
  font-size: 15px !important;
}

.NFTButton {
  width: 330px;
  height: 90px;
  background-color: rgb(74, 148, 232);
  font-size: 18px;
  color: white;
  border: rgb(74, 148, 232);
  border-radius: 20px;
  text-align: center;
}

.NFTsOnAuctionButton {
  position: relative;
  width: 330px;
  height: 90px;
  background-color: rgb(52, 121, 199);
  font-size: 18px;
  color: white;
  border: rgb(74, 148, 232);
  border-radius: 20px;
  text-align: center;
}

.NFTsOnAuctionButton::after {
  content: url('../assets/NFTAuction.svg');
  position: absolute;
  top: 5px;
  right: 5px;
}
</style>
