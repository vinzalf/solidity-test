import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.6.12",
      },
      {
        version: "0.8.20",
      },
      {
        version: "0.8.27",
      },
    ],
  },

};

export default config;
