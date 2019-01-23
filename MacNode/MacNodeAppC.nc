
#define NEW_PRINTF_SEMANTICS
#include <Timer.h>
#include "printf.h"
#include "MacNode.h"

configuration MacNodeAppC {
}
implementation {
  components MainC;
  components LedsC;
  components RandomC;
  components PrintfC;
  components SerialStartC;

  components MacNodeC as App;
  components ActiveMessageC;
  components new TimerMilliC() as TDMATimer;
  components new TimerMilliC() as BackoffTimer;
  components new TimerMilliC() as BackoffaTimer;
  components new TimerMilliC() as BackoffbTimer;
  components new TimerMilliC() as AckTimer;
  components new TimerMilliC() as AckaTimer;
  components new TimerMilliC() as AckbTimer;
  components new TimerMilliC() as CSMATimer;
  components new TimerMilliC() as CountTimer;
  components new TimerMilliC() as AdjustTimer;
  
  components new AMSenderC(AM_ONLINE) as ONSend;
  components new AMSenderC(AM_SCHDATA) as SCHDATASend;
  components new AMSenderC(AM_APPDATA) as APPDATASend;

  components new AMReceiverC(AM_TPDISCOVERY) as TPReceive;
  components new AMReceiverC(AM_SCHEDULE) as SCHEDULEReceive;
  components new AMReceiverC(AM_ACK) as ACKReceive;
  components new AMReceiverC(AM_ACKA) as ACKaReceive;
  components new AMReceiverC(AM_ACKB) as ACKbReceive;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Random -> RandomC;
  App.AMControl -> ActiveMessageC;
  App.Packet -> ActiveMessageC;
  App.AMPacket -> ActiveMessageC;

  App.ONSend -> ONSend;
  App.SCHDATASend -> SCHDATASend;
  App.APPDATASend -> APPDATASend;

  App.TPReceive -> TPReceive;
  App.SCHEDULEReceive -> SCHEDULEReceive;
  App.ACKReceive -> ACKReceive;
  App.ACKaReceive -> ACKaReceive;
  App.ACKbReceive -> ACKbReceive;

  App.TDMATimer -> TDMATimer;
  App.BackoffTimer -> BackoffTimer;
  App.BackoffaTimer -> BackoffaTimer;
  App.BackoffbTimer -> BackoffbTimer;
  App.AckTimer -> AckTimer;
  App.AckaTimer -> AckaTimer;
  App.AckbTimer -> AckbTimer;
  
  App.CSMATimer -> CSMATimer;
  App.CountTimer -> CountTimer;
  App.AdjustTimer -> AdjustTimer;

  //Nasty hack since no uniform way of prividing LPL support as of yet
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_TMOTE) || defined(PLATFORM_MICAZ) || defined(PLATFORM_Z1)
  components CC2420ActiveMessageC as LPLProvider;
  App.LPL -> LPLProvider;
#endif

#if defined(PLATFORM_MICA2)
  components CC1000CsmaRadioC as LPLProvider;
  App.LPL -> LPLProvider;
#endif

#if defined(PLATFORM_IRIS) || defined(PLATFORM_UCMINI)
  components ActiveMessageC as LPLProvider;
  App.LPL -> LPLProvider;
#endif
}







