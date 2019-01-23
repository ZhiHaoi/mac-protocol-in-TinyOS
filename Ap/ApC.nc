#include <Timer.h>
#include "printf.h"
#include "Ap.h"


module ApC {
  uses {
    interface Boot;
    interface Leds;
    interface Random;
    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
    interface AMSend as TPSend;                  //Topology Packet Send
    interface AMSend as SCHEDULESend;           //Schedule Packet Send
    interface AMSend as ACKSend;               //ACK Packet Send for Online Packets.
    interface AMSend as ACKaSend;              //ACK for Schedule Data Packets.
    interface AMSend as ACKbSend;              //ACK for Application Data Packets.

    interface Receive as ONReceive;           //ONline Packet Receive.
    interface Receive as SCHDATAReceive;     //Schedule date Packet Receive.
    interface Receive as APPDATAReceive;    //Application data Packet Receive.

    interface Timer<TMilli> as SCHSendTimer;
    interface Timer<TMilli> as BackoffTimer;
    interface Timer<TMilli> as BackoffaTimer;
    interface Timer<TMilli> as BackoffbTimer;
    interface Timer<TMilli> as PrintfTimer;
    interface Timer<TMilli> as CountTimer;

    interface Timer<TMilli> as AdjustTimer;
    interface Timer<TMilli> as DelayTimer;
  }
}
implementation {

  message_t pkt;
  tpdis_t tpmsg;  //Topology Discovery Packet.
  ack_t ackmsg;    //ACK Packet.
  ack_t ackamsg;
  ack_t ackbmsg;

  //online_t *onmsg;  //Online Packet
  sch_t schmsg;
  schdata_t *schdatamsg;
  appdata_t *appdatamsg;

  tp_table TPTable[31];  //Topology Table

  bool sendbusy = FALSE;  //sendbusy is TRUE when event Send occured.
  uint8_t sendtimes = 3;
  uint8_t nodes_num = 0;   //nodes number.

  uint32_t currenttime = 0;
  uint32_t nexttime;

  uint8_t i;
  uint8_t j;

  /******Tasks******/
  task void TPSendTask();    //Send Tpdiscovery Packet
  task void ACKSendTask();   //Send Ack Packet
  task void ACKaSendTask();
  task void ACKbSendTask();
  task void SCHEDULESendTask();

  /******Use LEDs to report various status issues.******/
  void report_problem()   { call Leds.led0Toggle(); }
  void report_sent()      { call Leds.led1Toggle(); }
  void report_received()  { call Leds.led2Toggle(); }

  /************************Tasks Implementation************************/
  //Topology Packet Send Task.
  task void TPSendTask() {
    if(!sendbusy && sizeof(tpmsg) <= call TPSend.maxPayloadLength())
      {
        tpmsg.packetid = 0x01;
        tpmsg.apid = TOS_NODE_ID;

        memcpy(call TPSend.getPayload(&pkt, sizeof(tpmsg)), &tpmsg, sizeof(tpmsg));
        if (call TPSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(tpmsg)) == SUCCESS)
          sendbusy = TRUE;
     }
  }

  //Ack Packet Send Task.
  task void ACKSendTask() {
    if (!sendbusy && sizeof(ackmsg) <= call ACKSend.maxPayloadLength())
      {
        memcpy(call ACKSend.getPayload(&pkt, sizeof(ackmsg)), &ackmsg, sizeof(ackmsg));
        if (call ACKSend.send(ackmsg.des, &pkt, sizeof(ackmsg)) == SUCCESS)
          sendbusy = TRUE;
      }
  }

  task void ACKaSendTask() {
    if (!sendbusy && sizeof(ackamsg) <= call ACKaSend.maxPayloadLength())
      {
        memcpy(call ACKaSend.getPayload(&pkt, sizeof(ackamsg)), &ackamsg, sizeof(ackamsg));
        if (call ACKaSend.send(ackamsg.des, &pkt, sizeof(ackamsg)) == SUCCESS)
          sendbusy = TRUE;
      }
  }

  task void ACKbSendTask() {
    if (!sendbusy && sizeof(ackbmsg) <= call ACKbSend.maxPayloadLength())
      {
        memcpy(call ACKbSend.getPayload(&pkt, sizeof(ackbmsg)), &ackbmsg, sizeof(ackbmsg));
        if (call ACKbSend.send(ackbmsg.des, &pkt, sizeof(ackbmsg)) == SUCCESS)
          sendbusy = TRUE;
      }
  }


  // Schedule Packet Send Task.
  task void SCHEDULESendTask() {
    if (!sendbusy && sizeof(schmsg) <= call SCHEDULESend.maxPayloadLength())
      {
        memcpy(call SCHEDULESend.getPayload(&pkt, sizeof(schmsg)), &schmsg, sizeof(schmsg));
        if (call SCHEDULESend.send(AM_BROADCAST_ADDR, &pkt, sizeof(schmsg)) == SUCCESS)
          sendbusy = TRUE;
      }
    else printf("Schedule Send Error.\n");
  }

  /****************************Functions****************************/
  void startBackoffTimer() {
    call BackoffTimer.startOneShot(call Random.rand16() % 5 + 1);
  }

  void stopBackoffTimer() {
    call BackoffTimer.stop();
  }

  void startBackoffaTimer() {
    call BackoffaTimer.startOneShot(call Random.rand16() % 5 + 1);
  }

  void stopBackoffaTimer() {
    call BackoffaTimer.stop();
  }

  void startBackoffbTimer() {
    call BackoffbTimer.startOneShot(call Random.rand16() % 5 + 1);
  }

  void stopBackoffbTimer() {
    call BackoffbTimer.stop();
  }

  void startPrintfTimer() {
    call PrintfTimer.startPeriodic( 5000 );
  }

  //Send Schedule Packet Timer.
  void startSCHSendTimer() {
    call SCHSendTimer.startOneShot( 3000 );
  }

  void stopSCHSendTimer() {
    call SCHSendTimer.stop();
  }

  void startCountTimer() {
    call CountTimer.startPeriodic( 200 );
  }

  void stopCountTimer() {
    call CountTimer.stop();
  }

  void startAdjustTimer() {
    call AdjustTimer.startOneShot( ADJUST_TIME );   //Every 3 minutes fired AdjustTimer.
  }

  void stopAdjustTimer() {
    call AdjustTimer.stop();
  }

  /****************************Events********************************/

  event void Boot.booted() {
    if (call AMControl.start() != SUCCESS)
      report_problem();
    startPrintfTimer();
  }

  event void AMControl.startDone(error_t err) {
    if (err != SUCCESS)
      call AMControl.start();
    call DelayTimer.startOneShot(10000);
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void DelayTimer.fired() {
    post TPSendTask();
  }

  event void BackoffTimer.fired() {
    post ACKSendTask();
  }

  event void BackoffaTimer.fired() {
    post ACKaSendTask();
  }

  event void BackoffbTimer.fired() {
    post ACKbSendTask();
  }

  event void CountTimer.fired() {
    if(currenttime < nexttime)
      currenttime = currenttime + 200;
    else {
      printf("Sync Time.\n");
      //currenttime = 0;
      startSCHSendTimer();
      stopCountTimer();
    }
  }

  event void AdjustTimer.fired() {
    printf("Adjust Time.\n");
    post TPSendTask();
  }

  event void SCHSendTimer.fired() {
    //schmsg.packetid = 0x04;
    schmsg.nodesnum = nodes_num;
    schmsg.currenttime = currenttime + 10;
    schmsg.nexttime = currenttime + 10000; //10s    10000.

    //currenttime = 0;
    //nexttime = schmsg.nexttime;


    for(j = 1;j <= nodes_num;j++) {
      schmsg.nodeid[j] = TPTable[j].nodeid;
      //printf("Node ID: %u....", TPTable[j].nodeid);
      schmsg.nodeslot[j] = j*200;
    }
    post SCHEDULESendTask();
  }

  event void PrintfTimer.fired() {
    printf("Nodes number: %u \n", nodes_num);
    for(i = 1;i <= nodes_num;i++) {
      printf("Node: %u    ", TPTable[i].nodeid);
      printf("Node State: %u   \n", TPTable[i].nodestate);
    }
    printfflush();
  }

  event void TPSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS) {
      report_sent();
      printf("Topology Packet Send Done.\n");
      startSCHSendTimer();   //In 1s Send Schedule Packet.
      startAdjustTimer();    //In 3mins Send Topology Packet.
    }
    else {
      report_problem();
      post TPSendTask();
    }
    sendbusy = FALSE;
  }

  event void ACKSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS) {
      report_sent();
      printf("Ack Packet Send Done. \n");
    }
    else {
      report_problem();
      post ACKSendTask();
    }
    sendbusy = FALSE;
  }

  event void ACKaSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS)
      report_sent();
    else {
      report_problem();
      post ACKaSendTask();
    }
    sendbusy = FALSE;
  }

  event void ACKbSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS)
      report_sent();
    else {
      report_problem();
      post ACKbSendTask();
    }
    sendbusy = FALSE;
  }

  event void SCHEDULESend.sendDone(message_t* msg, error_t error) {
    if(error == SUCCESS) {
      report_sent();
      printf("Schedule Packet Send Done. \n");
      nexttime = currenttime + 10000;
      startCountTimer();
    }
    else {
      report_problem();
      post SCHEDULESendTask();
    }
    sendbusy = FALSE;
  }

  event message_t* ONReceive.receive(message_t* msg, void* payload, uint8_t len) {
    online_t *onmsg = payload;
    report_received();
    printf("Online Packet Received. \n");
    printf("Node ID: %u \n", onmsg->nodeid);
    ackmsg.des = onmsg->nodeid;
    nodes_num++;
    TPTable[nodes_num].nodeid = onmsg->nodeid;
    TPTable[nodes_num].nodestate = 1;

    ackmsg.packetid = 0x03;
    //startBackoffTimer();
    return msg;
  }

  event message_t* SCHDATAReceive.receive(message_t* msg, void* payload, uint8_t len) {
    report_received();
    printf("Schedule Data Packet Received. \n");
    schdatamsg = payload;
    ackamsg.des = schdatamsg->nodeid;
    ackamsg.packetid = 0x06;
    printf("NodeID: %u, Schedule Packet.\n", schdatamsg->nodeid);

    //startBackoffaTimer();
    return msg;
  }

  event message_t* APPDATAReceive.receive(message_t* msg, void* payload, uint8_t len) {
    report_received();
    printf("Application Data Packet Received. \n");
    appdatamsg = payload;
    ackbmsg.des = appdatamsg->nodeid;
    ackbmsg.packetid = 0x08;
    printf("Currenttime: %lu, Timestamp: %lu.\n", currenttime, appdatamsg->timestamp);
    printf("NodeID: %u, Delay Time: %lu\n", appdatamsg->nodeid, currenttime - (appdatamsg->timestamp));

    //startBackoffbTimer();
    return msg;
  }
}
