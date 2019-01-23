#include <Timer.h>
#include <math.h>
#include "printf.h"
#include "MacNode.h"

module MacNodeC {
  uses {
    interface Boot;
    interface Leds;
    interface Random;
    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
    interface AMSend as ONSend;                            //Online Packet Send
    interface AMSend as SCHDATASend;                      //Schedule data Packet Send
    interface AMSend as APPDATASend;                     //Application data Packet Send

    interface Receive as TPReceive;                     //Topology Packet Receive
    interface Receive as SCHEDULEReceive;              //Schedule Packet Receive
    interface Receive as ACKReceive;                  //Ack for Online Packets.
    interface Receive as ACKaReceive;                 //Ack for Schedule Data Packets.
    interface Receive as ACKbReceive;                 //Ack for Application Data Packets.

    interface Timer<TMilli> as TDMATimer;
    interface Timer<TMilli> as BackoffTimer;         //Backoff to Send Online Packets.
    interface Timer<TMilli> as BackoffaTimer;        //Backoff to Send Schedule Data Packets.
    interface Timer<TMilli> as BackoffbTimer;        //Backoff to Send Application Data Packets.
    interface Timer<TMilli> as AckTimer;             //Ack for Online Packets.
    interface Timer<TMilli> as AckaTimer;            //Ack for Schedule Data Packets.
    interface Timer<TMilli> as AckbTimer;            //Ack for Application Data Packets.
    interface Timer<TMilli> as CSMATimer;
    interface Timer<TMilli> as CountTimer;
    interface Timer<TMilli> as AdjustTimer;

    interface LowPowerListening as LPL;
  }
}
implementation {

  message_t pkt;
  message_t pkt2;
  message_t pkt3;

  online_t onmsg;
  tpdis_t *tpmsg;
  ack_t *ackmsg;
  ack_t *ackamsg;
  ack_t *ackbmsg;

  sch_t *schmsg;
  schdata_t schdatamsg;
  appdata_t appdatamsg;


  bool online = FALSE;             //whether Ap received Node's Online Packets(whether node is Online).
  bool sendbusy = FALSE;
  bool onmsgack = FALSE;           //whether nodes received Online Packets' ACK.
  bool schdatamsgack = FALSE;      //whether nodes received Schedule Data Packets' ACK.
  bool appdatamsgack = FALSE;      //whether nodes received Application Data Packets' ACK.

  uint8_t nodes_num;

  uint32_t currenttime;
  uint32_t nexttime;
  uint8_t nodeslot;
  uint8_t i;
  uint8_t schnum = 0;

  uint8_t apid;

  uint8_t k;
  static int Poisson();

  /**************************************Tasks**************************************/
  task void ONSendTask();
  task void SCHDATASendTask();
  task void APPDATASendTask();

  /******************Use LEDs to report various status issues.****************/
  void report_problem() { call Leds.led0Toggle(); }
  void report_sent() { call Leds.led1Toggle(); }
  void report_received() { call Leds.led2Toggle(); }

  /**************************Tasks Implementation****************************/
  task void ONSendTask() {
    if (!sendbusy && sizeof(onmsg) <= call ONSend.maxPayloadLength())
      {
        onmsg.packetid = 0x02;
        onmsg.nodeid = TOS_NODE_ID;
        printf("Node ID: %u \n", onmsg.nodeid);

        memcpy(call ONSend.getPayload(&pkt, sizeof(onmsg)), &onmsg, sizeof(onmsg));
        if (call ONSend.send(0, &pkt, sizeof(onmsg)) == SUCCESS)
          sendbusy = TRUE;
      }
    else printf("Online Packet Send Error. \n");
  }

  task void SCHDATASendTask() {
    if (!sendbusy && sizeof(schdatamsg) <= call SCHDATASend.maxPayloadLength())
      {
        schdatamsg.packetid = 0x05;
        schdatamsg.nodeid = TOS_NODE_ID;
        schdatamsg.des = apid;
        schdatamsg.heartbeat = 1;

        memcpy(call SCHDATASend.getPayload(&pkt, sizeof(schdatamsg)), &schdatamsg, sizeof(schdatamsg));
        if (call SCHDATASend.send(0, &pkt, sizeof(schdatamsg)) == SUCCESS)
          sendbusy = TRUE;
      }
    else printf("Schedule Packet Send Error.");
  }

  task void APPDATASendTask() {
    if (!sendbusy && sizeof(appdatamsg) <= call APPDATASend.maxPayloadLength())
      {
        appdatamsg.packetid = 0x07;
        appdatamsg.nodeid = TOS_NODE_ID;
        appdatamsg.des = apid;
        appdatamsg.timestamp = currenttime;
        printf("Timestamp: %lu \n", appdatamsg.timestamp);

        memcpy(call APPDATASend.getPayload(&pkt, sizeof(appdatamsg)), &appdatamsg, sizeof(appdatamsg));
        if (call APPDATASend.send(0, &pkt, sizeof(appdatamsg)) == SUCCESS)
          sendbusy = TRUE;
      }
    else printf("Application Packet Send Error.\n");

  }


  /**************************Funcctions*******************************/
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


  void startAckTimer() {
    call AckTimer.startOneShot( 10 );
  }

  void stopAckTimer() {
    call AckTimer.stop();
  }

  void startAckaTimer() {
    call AckaTimer.startOneShot( 10 );
  }

  void stopAckaTimer() {
    call AckaTimer.stop();
  }

  void startAckbTimer() {
    call AckbTimer.startOneShot( 10 );
  }

  void stopAckbTimer() {
    call AckbTimer.stop();
  }

  void startCSMATimer() {
    printf("Poisson Random : %u \n", Poisson());
    call CSMATimer.startPeriodic( Poisson() * 20 + 300 );
  }

  void stopCSMATimer() {
    call CSMATimer.stop();
  }

  void startCountTimer() {
    call CountTimer.startPeriodic( 200 );
  }

  void stopCountTimer() {
    call CountTimer.stop();
  }

  void startTDMATimer() {
    call TDMATimer.startPeriodic(nodeslot + schnum * (nodes_num * 200));
  }

  void stopTDMATimer() {
    call TDMATimer.stop();
  }

  void startAdjustTimer() {
    call AdjustTimer.startOneShot(ADJUST_TIME - 100);
  }

  void stopAdjustTimer() {
    call AdjustTimer.stop();
  }

  /******************Generate a Poisson Random Variable.*************************/

  static int Poisson() {
    uint16_t u;
    double lambda;
    double p,f;

    u = (call Random.rand16() % 100);
    lambda = 20;
    p = (1/exp(lambda)) * 100;
    f = p;
    k = 0;

    while(u >= f) {
      k = k+1;
      p = (lambda*p) / k;
      f = f + p;
    }
    return k;
  }


  /********************************Events************************************/

  event void Boot.booted() {
    //call LPL.setLocalWakeupInterval(LPL_INTERVAL);
    if (call AMControl.start() != SUCCESS)
      report_problem();
  }

  event void AMControl.startDone(error_t err) {
    if (err != SUCCESS)
      call AMControl.start();
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void BackoffTimer.fired() {
    post ONSendTask();
  }

  event void BackoffaTimer.fired() {
    post SCHDATASendTask();
  }

  event void BackoffbTimer.fired() {
    post APPDATASendTask();
  }

  event void AckTimer.fired() {
    if (!onmsgack)        //if received ack message in 10ms, onmsgack is TRUE.
      post ONSendTask();
  }

  event void AckaTimer.fired() {
    if (!schdatamsgack)
      post SCHDATASendTask();
  }

  event void AckbTimer.fired() {
    if (!appdatamsgack)
      post APPDATASendTask();
  }

  event void CountTimer.fired() {
    if(currenttime < nexttime)
      currenttime = currenttime + 200;
    else {
      printf("Sync Time.\n");
      printf("Current Time: %lu \n", currenttime);
      schnum = 0;
      stopCSMATimer();
      stopTDMATimer();
      stopCountTimer();
    }
  }

  event void AdjustTimer.fired() {
    printf("Adjust Time.\n");
    stopCountTimer();
    stopCSMATimer();
    stopTDMATimer();
  }

  event void CSMATimer.fired() {
    printf("CSMA Timer Fired.\n");
    startBackoffbTimer();
  }

  event void TDMATimer.fired() {
    printf("TDMA Timer Fired.\n");
    schnum = schnum+1;
    startBackoffaTimer();
  }

  event void ONSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS) {
      report_sent();
      printf("Online Packet Send Done.\n");

      /*start AckTimer. If didn't receive ack message in 10ms,then resend online packet.*/
      //startAckTimer();
    }
    else {
      report_problem();
      post ONSendTask();
    }
    sendbusy = FALSE;
  }

  event void SCHDATASend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS) {
      report_sent();
      printf("Schedule Data Packet Send Done.\n");
      schdatamsgack = FALSE;

      /*start AckTimer. If didn't receive ack message in 10ms,then resend Schedule Data packet.*/
      //startAckaTimer();
    }
    else {
      report_problem();
      post SCHDATASendTask();
    }
    sendbusy = FALSE;
  }

  event void APPDATASend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS) {
      report_sent();
      printf("Application Data Packet Send Done.\n");
      appdatamsgack = FALSE;

      /*start AckTimer. If didn't receive ack message in 10ms,then resend Application Data Packets.*/
      //startAckbTimer();
    }
    else {
      report_problem();
      post APPDATASendTask();
    }
    sendbusy = FALSE;
  }

  //Topology Packet Receive Event.
  event message_t* TPReceive.receive(message_t* msg, void* payload, uint8_t len) {
    report_received();
    printf("Topology Packet Received.\n");
    tpmsg = payload;
    apid = tpmsg->apid;
    onmsg.des = apid;
    printf("ApID: %u\n", apid);
    startBackoffTimer();

    startAdjustTimer();
    return msg;
  }

  //Schedule Packet Receive Event.
  event message_t* SCHEDULEReceive.receive(message_t* msg, void* payload, uint8_t len) {
    report_received();
    printf("Schedule Packet Received.\n");
    schmsg = payload;
    nodes_num = schmsg->nodesnum;
    currenttime = schmsg->currenttime;    //1.
    nexttime = schmsg->nexttime;          //10000.
    
    startCountTimer();

    for(i = 1;i <= nodes_num;i++) {
      if (schmsg->nodeid[i] == TOS_NODE_ID)
        nodeslot = schmsg->nodeslot[i];
    }

    startTDMATimer();
    startCSMATimer();

    return msg;
  }

  event message_t* ACKReceive.receive(message_t* msg, void* payload, uint8_t len) {
    report_received();
    printf("Ack Packet Received.\n");
    ackmsg = payload;

    online = TRUE;
    onmsgack = TRUE;

    return msg;
  }

  event message_t* ACKaReceive.receive(message_t* msg, void* payload, uint8_t len) {
    report_received();
    ackamsg = payload;

    schdatamsgack = TRUE;
    return msg;
  }

  event message_t* ACKbReceive.receive(message_t* msg, void* payload, uint8_t len) {
    report_received();
    ackbmsg = payload;

    appdatamsgack = TRUE;
    return msg;
  }
}
