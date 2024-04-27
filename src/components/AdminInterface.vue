<template>
    <div id="app">
        <div id="head">
            <h1>Admin Area</h1>

            <p class="text">Address : {{ Address }}</p>

            <p v-if="isLoading" class="balanceLoading">Loading Account Balance...</p>

            <p v-else class="text">Account Balance: {{
                AccountBalance !== 0 ? Math.floor(AccountBalance * 1000000) / 1000000
                    : AccountBalance
                }} ETH</p>

            <p class="text">Total NFT : {{ allNFTNumber }}</p>
            <hr/>
        </div>

        <br/>
        <br/>
        <br/>
        <br/>
        <br/>
        <br/>
        <br/>

        <p v-for="(item, index) in TotalNFTGroup" :key="item">
            <button name="NFTButton"
                    class="NFTButton"
                    :class="{
        'NFTsOnSaleButton': PriceGroup[index] !== 0,
        'NFTsOnAuctionButton':currentAuctionNFTs.includes(TotalNFTGroup[index]) }"
                    :key="index"
                    :disabled="PriceGroup[index] !== 0">
                <small class="BtnTitle">NFT{{ index + 1 }}</small>
                <br/>
                <small class="BtnText">Token ID:{{ item }}</small>
                <br/>
                <small v-if="PriceGroup[index] !== 0" class="BtnText">Selling Price: {{ PriceGroup[index] }} ETH</small>
            </button>
        </p>

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

        <el-dialog title="Mint NFTs" v-model="mintFlag" width="380px" center style="margin-top: 50px">
            <el-form :model="MintNFTsFrom">
                <el-form-item label="To" :label-width="formLabelWidth">
                    <el-input v-model="MintNFTsFrom.to" autocomplete="off"
                              placeholder="Recipient's Address" style="width: 250px"></el-input>
                </el-form-item>
                <el-form-item label="Quantity" :label-width="formLabelWidth">
                    <el-input v-model="MintNFTsFrom.quantity" autocomplete="off"
                              placeholder="Mint Quantity (e.g., 10)" style="width: 250px"></el-input>
                </el-form-item>
                <el-form-item label="Location" :label-width="formLabelWidth">
                    <el-input v-model="MintNFTsFrom.location" autocomplete="off"
                              placeholder="Optional Location" style="width: 250px"></el-input>
                </el-form-item>
                <el-form-item label="Channel" :label-width="formLabelWidth">
                    <el-input v-model="MintNFTsFrom.channel" autocomplete="off"
                              placeholder="Optional Channel" style="width: 250px"></el-input>
                </el-form-item>
                <el-form-item label="AP ID" :label-width="formLabelWidth">
                    <el-input v-model="MintNFTsFrom.AP_ID" autocomplete="off"
                              placeholder="Access Point ID" style="width: 250px"></el-input>
                </el-form-item>
            </el-form>

            <div style="text-align: center; margin-top: 20px;">
                <el-button @click="Cancel" style="margin-right: 20px; font-size: 16px;">Cancel</el-button>
                <el-button type="primary" @click="mintWiFiNFT" style="font-size: 16px; padding: 12px 20px;">Confirm</el-button>
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
                                v-model="AuctionNFTFrom.durationDay"
                                placeholder="Day  (WiFi)"
                                autocomplete="off">
                        </el-input>
                    </el-col>

                    <el-col class="line" :span="1">-</el-col>

                    <el-col :span="11">
                        <el-input
                                style="width: 100%;"
                                v-model="AuctionNFTFrom.durationHour"
                                placeholder="Hour  (WiFi)"
                                autocomplete="off">
                        </el-input>
                    </el-col>
                </el-form-item>

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
            <button name="MintNFT" class="btn" @click="confirmMintNFTs">Mint NFTs</button>
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

const sonyAbi = require("../script/sony.json");

const savedAdminPrivateKey = localStorage.getItem("AdministratorPrivateKey");

export default {
    name: 'AdminInterface',

    props: {
        msg: String
    },

    data() {
        return {
            CheckBoxState: false,

            contractInstance: null,

            durationDayValue: '',

            durationHourValue: '',

            MintNFTsFrom: {
                to: null,
                quantity: null,
                location: "",
                channel: "",
                AP_ID: null
            },

            AuctionNFTFrom: {
                durationDay: null,
                durationHour: null,
                biddingTimeDay: null,
                biddingTimeHour: null,
                beneficiary: null,
                bottomPrice: null,
            },

            formLabelWidth: "55px",

            isMinting: false,

            mintFlag: false,

            //竞拍方式出售
            auctionFlag: false,

            isAuction: false,

            isLoading: true,

            selectedNFTForAuction: null,

            TotalNFTGroup: [],

            allNFTNumber: 0,

            PriceGroup: [],

            currentAuctionNFTs: [],

            availableForSaleGroup: [],

            availableForAuctionGroup: [],

            AP_IDs: [],

            Address: "",

            AccountBalance: 0,

            NoNFT: false,

            ownedNFTsResult: null,

            currentAuctionNFTsResult: null,

            auctionReminderVisible: false,

            DurationDay_float: false,

            DurationHour_float: false,
        };
    },

    created() {
        this.AdminHasRefreshed()
    },

    async mounted() {
        this.Address = web3.eth.accounts.privateKeyToAccount(savedAdminPrivateKey).address;
        this.contractInstance = await this.createContractInstance(sonyAbi, contractAddress);
        this.AccountBalance = this.getBalance(this.Address)
            .then((balance) => {
                this.AccountBalance = balance;
                this.isLoading = false; // Set isLoading to false once balance is fetched
                localStorage.setItem("AccountBalance", balance);
            })
            .catch((error) => {
                console.error('获取账户余额失败:', error);
                this.isLoading = false; // Set isLoading to false even if an error occurs
            });
        await this.getOwnedAllNFT(this.Address);
        let NFTAuctionEndingTime = this.currentAuctionNFTsResult[6];
        let currentTime = new Date().getTime() / 1000
        this.auctionReminderVisible = true;
        for (let i = 0; i < NFTAuctionEndingTime.length; i++) {
            if (NFTAuctionEndingTime[i] < currentTime && this.auctionReminderVisible) {
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

        // todo
        async mintWiFiNFT() {
            const toValue = this.MintNFTsFrom.to;
            const quantityValue = Number(this.MintNFTsFrom.quantity);
            const locationValue = this.MintNFTsFrom.location;
            const channelValue = this.MintNFTsFrom.channel;
            const apIdValue = this.MintNFTsFrom.AP_ID;

            if (!isAddress(toValue)) {
                this.showError("Invalid Ethereum address");
                return;
            }
            if (!(quantityValue > 0 && this.isPositiveInteger(quantityValue))) {
                this.showError("Quantity must be a positive integer");
                return;
            }
            if (apIdValue == null) {
                this.showError("AP_ID cannot be null");
                return;
            }
            try {
                this.mintFlag = false;
                this.isMinting = true;
                const txCount = await web3.eth.getTransactionCount(this.Address);
                const mintInstance = this.contractInstance.methods.mint_WIFI_NFT(
                    toValue,
                    quantityValue,
                    locationValue,
                    channelValue,
                    apIdValue
                );
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
                await this.getOwnedAllNFT(this.Address);
                this.isMinting = false;
                Swal.fire({
                    position: "center",
                    icon: "success",
                    title: "NFTs minted successfully!",
                    showConfirmButton: false,
                    timer: 2500
                });
            } catch (error) {
                this.isMinting = false;
                this.showError(`Transaction failed: ${error.message}`);
            }
        },

        // todo
        //提交拍卖数据表单
        async submitInventoryForAuction() {
            const durationValue = this.TimeConversion(this.AuctionNFTFrom.durationDay, this.AuctionNFTFrom.durationHour)

            const biddingTime = this.TimeConversion(this.AuctionNFTFrom.biddingTimeDay, this.AuctionNFTFrom.biddingTimeHour)

            let beneficiary = String(this.AuctionNFTFrom.beneficiary);
            let bottomPrice = web3.utils.toWei(Number(this.AuctionNFTFrom.bottomPrice), 'ether');

            if(this.DurationDay_float || this.DurationHour_float) {
                this.showError("Duration must be a positive integer");
                this.DurationDay_float = false;
                this.DurationHour_float = false;
                return;
            }

            if (!(
                this.AuctionNFTFrom.durationDay >= 0 &&
                this.AuctionNFTFrom.durationHour >= 0 &&
                this.isPositiveInteger(durationValue)
            )) {
                this.showError("Duration must be a positive integer");
                return;
            }

            if (durationValue == null) {
                this.showError("Duration cannot be null");
                return
            }
            if (!(
                this.AuctionNFTFrom.biddingTimeDay >= 0 &&
                this.AuctionNFTFrom.biddingTimeHour >= 0 &&
                this.isPositiveInteger(durationValue)
            )) {
                this.showError("Auction duration must be a positive integer");
                return;
            }

            if (biddingTime == null) {
                this.showError("biddingTime cannot be null");
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
            if (!(bottomPrice > 0 && this.isPositiveInteger(durationValue))) {
                this.showError("Starting price must be a positive integer");
                return;
            }

            if (bottomPrice == null) {
                this.showError("Starting price cannot be null");
                return
            }
            if (this.selectedNFTForAuction === null) {
                this.showError("Please select the NFT you want to auction");
                return
            }

            try {
                this.auctionFlag = false;
                this.isAuction = true;
                const txCount = await web3.eth.getTransactionCount(this.Address);
                const auctionInstance = this.contractInstance.methods.startAuction(this.selectedNFTForAuction,
                    durationValue, biddingTime, beneficiary, bottomPrice)
                const auctionInstanceEncodedABI = auctionInstance.encodeABI();
                const txObject = {
                    nonce: txCount,
                    to: contractAddress,
                    gasLimit: 3000000,
                    gasPrice: web3.utils.toWei('2', 'gwei'),
                    data: auctionInstanceEncodedABI
                };
                const signed = await web3.eth.accounts.signTransaction(txObject, savedAdminPrivateKey);
                await web3.eth.sendSignedTransaction(signed.rawTransaction);
                await this.getOwnedAllNFT(this.Address);
                this.Cancel()
                this.isAuction = false;
                Swal.fire({
                    position: "center",
                    icon: "success",
                    title: "The NFT you selected is currently being auctioned!",
                    showConfirmButton: false,
                    timer: 2500
                });
            } catch (error) {
                this.isAuction = false;
                this.Cancel()
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

        // todo
        confirmMintNFTs() {
            this.mintFlag = true;
            this.MintNFTsFrom.to = this.Address;
            this.MintNFTsFrom.quantity = null;
            this.MintNFTsFrom.location = "";
            this.MintNFTsFrom.channel = "";
            this.MintNFTsFrom.AP_ID = null;
        },

        // todo
        confirmAuctionNFT() {
            this.auctionFlag = true;
            this.selectedNFTForAuction = null;
            this.AuctionNFTFrom.durationDay = null;
            this.AuctionNFTFrom.durationHour = null;
            this.AuctionNFTFrom.biddingTimeDay = null;
            this.AuctionNFTFrom.biddingTimeHour = null;
            this.AuctionNFTFrom.beneficiary = this.Address;
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

        // todo
        async getOwnedAllNFT(address) {
            this.availableForSaleGroup = [];
            this.availableForAuctionGroup = [];
            this.ownedNFTsResult = await this.contractInstance.methods.getOwnedNFTs(address).call();
            this.currentAuctionNFTsResult = await this.contractInstance.methods.getCurrentAuctionNFTs(address).call();

            if (this.ownedNFTsResult && typeof this.ownedNFTsResult === 'object' &&
                this.currentAuctionNFTsResult && typeof this.currentAuctionNFTsResult === 'object') {
                this.TotalNFTGroup = this.ownedNFTsResult[0];
                this.allNFTNumber = this.TotalNFTGroup.length;
                this.PriceGroup = this.ownedNFTsResult[1].map(wei => Number(web3.utils.fromWei(wei, 'ether')));
                this.AP_IDs = this.ownedNFTsResult[2];
                this.currentAuctionNFTs = this.currentAuctionNFTsResult[0];
                for (let i = 0; i < this.allNFTNumber; i++) {
                    if (this.PriceGroup[i] === 0 && Number(this.ownedNFTsResult[3][i]) === 0 &&
                        !this.currentAuctionNFTs.includes(this.TotalNFTGroup[i])) {
                        this.availableForSaleGroup.push(Number(this.TotalNFTGroup[i]));
                        this.availableForAuctionGroup.push(Number(this.TotalNFTGroup[i]))
                    }
                }
                if (this.allNFTNumber === 0) {
                    this.NoNFT = true;
                }
            } else {
                console.error("Invalid result structure:", this.ownedNFTsResult);
                Swal.fire({
                    icon: "error",
                    title: "Network Error!",
                    text: "Failed to connect to blockchain network!",
                });
            }
        },

        Cancel() {
            this.mintFlag = false;
            this.auctionFlag = false;
        },

        Exit() {
            setTimeout(this.BackToLoginPage, 300)
        },

        BackToLoginPage() {
            this.$router.push('/LogIn')
        },

        goToAuctionInfoPage() {
            this.$router.push('/AuctionInfo');
        },

        AdminHasRefreshed() {
            const AdminHasRefreshed = localStorage.getItem('AdminHasRefreshed');

            if (!AdminHasRefreshed) {
                window.location.reload()
                localStorage.setItem('AdminHasRefreshed', 'true');
            } else {
                localStorage.removeItem('AdminHasRefreshed');
            }
        },
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

.NFTsOnSaleButton {
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

.NFTsOnSaleButton::after {
    content: url('../assets/NFTSelling.svg');
    position: absolute;
    top: 5px;
    right: 5px;
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
