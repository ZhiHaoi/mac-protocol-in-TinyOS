/*MAC Version1.0*/

#ifndef MACNODE_H
#define MACNODE_H

/********Constants********/
enum {
  ADJUST_TIME = 180000,   //3mins
  LPL_INTERVAL = 10000,
  AM_TPDISCOVERY = 1,   //Send and Receive Topology Packets.
  AM_ONLINE = 2,        //Send and Receive Online Packets.
  AM_ACK = 3,           //Send and Receive Ack Packets.
  AM_SCHEDULE = 4,      //Send and Receive Schedule Packets.
  AM_SCHDATA = 5,       //Send and Receive Schedule Data Packets.
  AM_APPDATA = 6,        //Send and Receive Application Data Packets.
  AM_ACKA = 7,
  AM_ACKB = 8
};


/*****"**Packets structure********/

//Topology Packets.
typedef nx_struct tpdis {
  nx_uint8_t packetid;
  nx_uint8_t apid;
  nx_uint8_t currenttime;
} tpdis_t;

//Online Packets.
typedef nx_struct online {
  nx_uint8_t packetid;        /*ID of Packets*/ 
  nx_uint8_t nodeid;             /*ID od Nodes*/
  nx_uint8_t des;          /*destination*/
} online_t;

//Ack Packets.
typedef nx_struct ack {
  nx_uint8_t packetid;
  nx_uint8_t des;
  nx_uint8_t ackdata;
} ack_t;

//Schedule Packets.
typedef nx_struct schedule {
  //nx_uint8_t packetid;
  nx_uint8_t nodesnum;
  nx_uint32_t currenttime;
  nx_uint32_t nexttime;
  nx_uint8_t nodeid[7];
  nx_uint8_t nodeslot[7];
} sch_t;

//Schedule Data Packets.
typedef nx_struct schdata {
  nx_uint8_t packetid;
  nx_uint8_t nodeid;
  nx_uint8_t des;
  nx_uint8_t heartbeat;
} schdata_t;

//Application Data Packets.
typedef nx_struct appdata {
  nx_uint8_t packetid;
  nx_uint8_t nodeid;
  nx_uint8_t des;
  nx_uint32_t timestamp;
} appdata_t;



#endif
