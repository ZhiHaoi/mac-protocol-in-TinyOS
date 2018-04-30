
#define NEW_PRINTF_SEMANTICS
#include <Timer.h>
#include "printf.h"
#include "Ap.h"


configuration ApAppC {
}
implementation {
  components MainC;
  components LedsC;
  components RandomC;
  components PrintfC;
  components SerialStartC;
  components ApC as App;
  components ActiveMessageC;

  components new TimerMilliC() as SCHSendTimer;
  components new TimerMilliC() as Timerbackoff;
  components new TimerMilliC() as BackoffaTimer;
  components new TimerMilliC() as BackoffbTimer;
  components new TimerMilliC() as PrintfTimer;
  components new TimerMilliC() as CountTimer;
  components new TimerMilliC() as AdjustTimer;
  components new TimerMilliC() as DelayTimer;

  components new AMSenderC(AM_TPDISCOVERY) as TPSend;
  components new AMSenderC(AM_SCHEDULE) as SCHEDULESend;
  components new AMSenderC(AM_ACK) as ACKSend;
  components new AMSenderC(AM_ACKA) as ACKaSend;
  components new AMSenderC(AM_ACKB) as ACKbSend;

  components new AMReceiverC(AM_ONLINE) as ONReceive;
  components new AMReceiverC(AM_SCHDATA) as SCHDATAReceive;
  components new AMReceiverC(AM_APPDATA) as APPDATAReceive;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Random -> RandomC;
  App.AMControl -> ActiveMessageC;
  App.Packet -> ActiveMessageC;
  App.AMPacket -> ActiveMessageC;

  App.TPSend -> TPSend;
  App.SCHEDULESend -> SCHEDULESend;
  App.ACKSend -> ACKSend;
  App.ACKaSend -> ACKaSend;
  App.ACKbSend -> ACKbSend;

  App.ONReceive -> ONReceive;
  App.SCHDATAReceive -> SCHDATAReceive;
  App.APPDATAReceive -> APPDATAReceive;

  App.SCHSendTimer -> SCHSendTimer;
  App.BackoffTimer -> Timerbackoff;
  App.BackoffaTimer -> BackoffaTimer;
  App.BackoffbTimer -> BackoffbTimer;
  App.PrintfTimer -> PrintfTimer;
  App.CountTimer -> CountTimer;
  App.AdjustTimer -> AdjustTimer;

  App.DelayTimer -> DelayTimer;
}
