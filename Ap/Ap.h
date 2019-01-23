

#ifndef AP_H
#define AP_H

/********Constants********/
enum {
  ADJUST_TIME = 180000,  //3mins
  AM_TPDISCOVERY = 1,
  AM_ONLINE = 2,
  AM_ACK = 3,
  AM_SCHEDULE = 4,
  AM_SCHDATA = 5,
  AM_APPDATA = 6,
  AM_ACKA = 7,
  AM_ACKB = 8
};

/********Packets structure********/

typedef nx_struct tpdis {
  nx_uint8_t packetid;
  nx_uint8_t apid;
} tpdis_t;

typedef nx_struct online {
  nx_uint8_t packetid;
  nx_uint8_t nodeid;
  nx_uint8_t des;
} online_t;

typedef nx_struct ack {
  nx_uint8_t packetid;
  nx_uint8_t des;
  nx_uint8_t ackdata;
} ack_t;

typedef nx_struct schedule {
  //nx_uint8_t packetid
  nx_uint8_t nodesnum;
  nx_uint32_t currenttime;
  nx_uint32_t nexttime;
  nx_uint8_t nodeid[7];
  nx_uint8_t nodeslot[7];
} sch_t;

typedef nx_struct schdata {
  nx_uint8_t packetid;
  nx_uint8_t nodeid;
  nx_uint8_t des;
  nx_uint8_t heartbeat;
} schdata_t;

typedef nx_struct appdata {
  nx_uint8_t packetid;
  nx_uint8_t nodeid;
  nx_uint8_t des;
  nx_uint32_t timestamp;
} appdata_t;

/********Topology Table********/
typedef nx_struct tptable {
  nx_uint8_t nodeid;
  nx_uint8_t nodestate;
  nx_uint8_t nodemsg;
} tp_table;


#endif
