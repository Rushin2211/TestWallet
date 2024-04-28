import WelcomeToUse from '@/components/WelcomeToUse.vue'
import LogIn from '@/components/LogIn.vue'
import UserInterface from '@/components/UserInterface.vue'
import AdminInterface from '@/components/AdminInterface.vue'
import CreateAccount from '@/components/CreateAccount.vue'
import AuctionInfo from '@/components/AuctionInfo.vue'
import TestPage from "@/components/TestPage.vue"
import TestPage1 from "@/components/TestPage1.vue"
import {createRouter, createWebHashHistory} from "vue-router";

const routes = [
    {
        path: '/',
        name: 'WelcomeToUse',
        component: WelcomeToUse
    },

    {
        path: '/LogIn',
        name: 'LogIn',
        component: LogIn
    },

    {
        path: '/UserInterface',
        name: 'UserInterface',
        component: UserInterface
    },

    {
        path: '/AdminInterface',
        name: 'AdminInterface',
        component: AdminInterface
    },

    {
        path: '/CreateAccount',
        name: 'CreateAccount',
        component: CreateAccount
    },

    {
        path: '/AuctionInfo',
        name: 'AuctionInfo',
        component: AuctionInfo
    },

    {
        path: '/TestPage',
        name: 'TestPage',
        component: TestPage,
    },

    {
        path: '/TestPage1',
        name: 'TestPage1',
        component: TestPage1,
    },

];

const router = createRouter({
    history: createWebHashHistory(),
    routes,
});

export default router;