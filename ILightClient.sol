pragma solidity 0.6.4;

interface ILightClient {

    function getAppHash(uint64 height) external view returns (bytes32);

    function isHeaderSynced(uint64 height) external view returns (bool);

    function getSubmitter(uint64 height) external view returns (address payable);

}