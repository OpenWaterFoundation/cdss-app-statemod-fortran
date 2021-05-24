c divrplr - Type 33 operating rule
c           From a Reservoir and reuse plan to a diversion or reservoir or carrier
c           with reuse by exchange.
c           Note can exchange the diversion or depletion.
c_________________________________________________________________NoticeStart_
c StateMod Water Allocation Model
c StateMod is a part of Colorado's Decision Support Systems (CDSS)
c Copyright (C) 1994-2021 Colorado Department of Natural Resources
c 
c StateMod is free software:  you can redistribute it and/or modify
c     it under the terms of the GNU General Public License as published by
c     the Free Software Foundation, either version 3 of the License, or
c     (at your option) any later version.
c 
c StateMod is distributed in the hope that it will be useful,
c     but WITHOUT ANY WARRANTY; without even the implied warranty of
c     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
c     GNU General Public License for more details.
c 
c     You should have received a copy of the GNU General Public License
c     along with StateMod.  If not, see <https://www.gnu.org/licenses/>.
c_________________________________________________________________NoticeEnd___
c
      subroutine divrplR(iw,l2,ishort,divactx,divacty,ncallx)
c
c
c _________________________________________________________
c	Program Description
c
c     DivrplR; Type 33
c              From a Reservoir and reuse plan to 
c              To a diversion or reservoir or carrier
c              with reuse by exchange 
c	             Note can exchange the diversion or depletion
c
c              Called by Execut
c _________________________________________________________
c
c       Update History
c
c
c rrb 2021/05/02; Runtime error tracking
c rrb 2021/04/18; Compiler warning
c
c rrb 2020/12/12; Corrected a problem related to using variable
c                 ncarry as a stream location w/o realizing it
c                 gets reset in SetLoss.  Therefore
c                 revised ncarry to be 0 or 1 as follows:
c                 0= no carrier and 1 = yes carrier
c                 Set variable ncarid to be the carrier location
c                 on the stream
c
c                 Set qdiv(xx,38) to report as carried at all
c                   destination types (div, isf, res) 

c
c rrb 2020/12/10; Correction source is a reservoir & plan (not priority)
cx        qres(2,nrD)=qres(2,nrD)+divafL
c         qres(4,nrD)=qres(4,nrD)+divafL
c
c rrb 2020/12/07; Remove qdiv(28,xx) it is not used since 2010
c rrb 2020/12/07; Correction should be 
c                 qdiv(26,idcdd) = From River by Other not 
c                 qdiv(20,idcdd) = From Carrier by Other       
c
c rrb 2011/11/29; Allow an instream flow destination
c
c rrb 2008/06/10; Allow return to river then diversion
c		  from a carrier again (internT = 1 Carrier, 2=Return)        
c
c rrb 04/12/29; Copy divRplR. Adjust for plans by:
c		source is a plan not a reservoir
c		remove references to replacement reservoirs (irep>0)
c		remove references to a water right limitation
c		add destination is a diversion
c
c _____________________________________________________________
c
c       Documentation
c         iw                    water right order
c         l2                    order of operating rule
c         ishort                shortage indicator 0=no, 1=yes
c         irep                  replace indicator 0=no, 1=yes
c
c         dcrdivx = dcrdiv(n)   water right
c         divdx = divd(n)       remaining water right amount
c
c         divact                actual diversion
c         divactx               actual plan release from divRplR
c         divacty               actual diversion from divRplR Note may
c                               not equal divactx if releasing for
c                               depletion
c
c       Other Key variables
c         icx   = 6             subroutine call #
c         ieff2 = 0             always use average efficiency
c               = 1             use max efficiency if ieffmax = 1
c         internT     		      Intervening structure type
c				                        1 = Carrier
c				                        2 = River
c         iopsou(1,l2) = nr     Source reservoir
c         iopsou(2,l2) = iown   Source reservoir account
c
c rrb 2005/11/12;             
c
c	        ipUse           	    Destination Reuse plan
c                          	    Note ipUse=ireuse(l2)
c         np            		    Source reuse plan
c                          	    Note np  =IOPSOU(3,l2)           
c
c         iopsou(4,l2) =        N/A
c                            
c	        cdivtyp(l2)  =        DIVERSION or DEPLETION
c	        icu =        =        0=DIVERSION or 1=DEPLETION
c
c         iExPoint(l2) =        Exchange Point
c	        iExchPt      =        iExPoint(l2)
c         iopsou(6,l2) =        Reservoir release type and efficiency
c                                0 = release to meet demand
c                               +n = release only if a CIR (IWR) exists
c                                   and limit release to not exceed
c                                   IWR/n,  
c                               Note nmax = min(nmax, effmax) to save 
c                                 iterating
c         ireltyp               Same as iopsou(6,l2)
c
c	        ipUse                 Reuse plan for return flows
c                               Note ipUse=ireuse(l2)
c
c         iopdes(1,l2) = nd     destination diversion or reservoir
c         iopdes(2,l2) = iuse   destination user
c
c	        nrD                   destination reservoir
c	        irow                  destination reservoir account

c
c         iopdesr(l2)           water right limit 0=no limit, +=limit
c
c         ipsta(np) = iscd      Plan (supply) river station
c         idvsta(np) = idcd     Diversion river station
c
c	        idcd                  Actual Diversion location. May be one 
c                               anything including a carrier
c	        idcdd			            Destination Diversion location on river
c	        idcdr                 Destination Reservoir location on river
c	        idcdc                 Destination carrier location on river
c	        idcdX			            destination but NOT A CARRIER
c
c         ndnnod (idcd) = ndnd  number of nodes downstream of diversion
c         ndnnod(iscd) = ndns   number of nodes downstream of supply
c
c         divcap(nd)            capacity
c         divmon(nd)            demand supplied this time step (grows
c                                 with each diversion each iteration)
c         divreq(iuse)          demand remaining this time step
c                                 (reduces with each diversion each
c                                 iteration)
c
c         divalo                allowable demand after adjusting for
c                                 demand, capacity, amount already
c                                 diverted this time step, water right
c                                 limit, etc.
c         divact                actual diversion
c	        pavail                minimum available flow 
c
c         qdiv(5                Carrier passing thru a structure (e.g. divcar)
c         qdiv(7                Source Reservoir
c         qdiv(18               Carrier through a structure
c
c         qdiv(19               From Carrier by Priority
c         qdiv(20               From Carrier by Other (Sto, Exc ...)
c         qdiv(21               From River by Other (Sto, Exc ...)
c                                 by Carrpl, DivrplR, ...
c         qdiv(26  		          From River by Other (Sto, Exc ...)
c	        qdiv(29               Exchange from a plan
c         qdiv(38               Report as carried water  
c
c ---------------------------------------------------------
c
c	        qres(2,ix)            From carrier to by Priority
c         qres(4.ix)            From carrier by Other
c         qres(8,ix)            From storage to river for use
c         qres(18,ix)           From River by Exchange, ... (Other)
c
c ---------------------------------------------------------
c
c         small                 a local limit used for convergence, etc.
c         iouta                 0 no detailed printout for avail
c                               n yes detailed printout for avail
c	        iwhy                  1 reason for no diversion
c	        ncallx		            number of times called per time step
c
c ---------------------------------------------------------
c		Loss Data
c	        OprLoss(l2) =         Transit loss (%) 
c	       		                    Transit loss is a true loss no routing
c	        ioprloss    =         int(OprLoss) carrier loss switch
c	       		                    + transit loss, maybe carrier loss
c	                              - 0 transit loss, maybe carrier loss
c	        TranLoss    =         Transit loss (fraction)
         
c	        OprLossC(l2,i) =      Conveyance loss from a carrier (%)
c	       		                    Conveyance loss gets routed to system
c	        OprLost=            	conveyance loss (cfs)
c               
c	        OprEff1 =           	source Carrier Efficiency 
c                                (1.0 - OprLoss(l2)/100)
c	        OprEffT =           	Total Carrier Efficiency 
c               
c	        effmaxT=	            Transit loss for a ditch 
c        
c	        ncarry                indicator at least 1 carrier
c	        ncnum                 # of carriers
c        
c         idcdX                 stream ID of destination diversion 
c                               (nd2) or reservoir or plan 

c _________________________________________________________
c	Dimensions
      include 'common.inc'
      character cwhy*45, cdestyp*12, cstaid1*12,
     1          rec12*12, ccarry*3, cpuse*3, cresid1*12, subtypX*8 
c
c
c ---------------------------------------------------------
c rrb 2021/05/02; Runtime error tracking
      character cCallBy*12
      cCallBy = 'Divrplr'
c
c _____________________________________________________________
c
c               Step 1a - Initialize general variables
c
c rrb 2021/04/18; Compiler warning
      iprob=0
      if(iprob.gt.0) goto 9999
c
c
c               Control debut printout
c		iout=0 none, iout=1 detailed, iout=2 summary
      subtypX='divrplr '
      iout=0
      ioutiw=0
      ioutIR=0
      
      if(ichk.eq.133) iout=2
      if(corid(l2).eq. ccall) ioutiw=iw

cx      write(nlog,*) '  DivRplR;  , corid(l2), ccall, ioutiw, iw'
cx      write(nlog,*) '  DivRplR; ', corid(l2), ccall, ioutiw, iw
      iouta=0
      ioff=0
      nd=0
      nr=0
      idcd=0
      imcd=0
c
c rrb 2021/04/18; Compiler warning
      irow=0
      idcdd=0
      nro=0
      idcdr=0
      ib=0
      ie=0

      small=0.001
      smalln=-1.0*small
      
      if(iout.eq.1) then
c       write(nlog,301) iyr, mon, iwx, iw, iout, ichk99
      endif
      
      if(iday.eq.0) then
        fac=mthday(mon)*factor
      else
        fac=factor
      endif
        

      ishort = 0      
c      
c
c rrb 2007/01/04; Use maximum efficiency if ieffmax=1     
c     ieff2=0
      ieff2=1
c
      rcu=0.0
      divact = 0.0
      divalo = 0.0
      divactx=0.0
      divacty=0.0
      dcrdivx=0.0
      divdx=0.0
      ndx=-1
      iuseX=-1
      
      pavail=-1.0/fac
      divcarry=-1.0/fac
      divreq1=-1.0/fac
      alocfs =-1.0/fac
      alocfsP=-1.0/fac
      alocfsR=-1.0/fac
      divalox=-1.0/fac
      relact=0.0/fac
      
      diveff1=-1.0/100.
      avail1=-1./fac
      qdiv29=-1./fac
      
      FrCarOth = -1./fac
      FrRivOth = -1./fac
      
      iwhy=-1
      cwhy='N/A'
      
      ccarry='No'
      cpuse='No'      
      if(intern(l2,1).gt.0) ccarry='Yes'      
      
      iExchPt=iExPoint(l2)
      icx=33
      
      lopr=0
      loprR=0
      noprS=0
c
c --------------------------------------------------------
      ndtype = iopdesr(l2)
      if(ndtype.eq.1) cdestyp='ISF Flow'
      if(ndtype.eq.2) cdestyp='Reservoir'
      if(ndtype.eq.3) cdestyp='Diversion'
      if(ndtype.eq.7) cdestyp='Plan     '
c
c ---------------------------------------------------------
c		f. Standard Carrier      
      nCarry=0
      ccarry='No'
      if(intern(l2,1).gt.0) then
        ccarry='Yes'
c
c rrb 2020/12/12; ncarry gets reset in setloss
cx      ncarry=intern(l2,1)
        ncarry=1
      endif      
c
c ---------------------------------------------------------
c rrb 2007/06/06; Add Carrier Loss
      call SetLoss(nlog, icx, l2, fac, 
     1 maxopr,   intern, Oprloss, OprLossC,
     1 ioprloss, nCarry, nRiver,  ncnum, 
     1 OprLost,  OprEff1, OprEffT, TranLoss, internT,internL,corid(l2))
c
c _________________________________________________________
c
c		             1b; Check avail array in
      call chekava(18, maxsta, numsta, avail, subtypX)
      if(iouta.gt.0) write(nlog,*) '  divRplR; OK going in'
c
c _________________________________________________________
c                Step 2. Check Printout on input or output
c

      ND  =IOPDES(1,l2)
c
c
c _________________________________________________________
c		             Step 3. Set CU limit switch      
      rec12=cDivTyp(l2)
      icu=0
      if(rec12(1:9).eq.'Diversion') icu=0
      if(rec12(1:9).eq.'Depletion') icu=1
c
c _________________________________________________________
c
c		             Step 3: Branch if not on this month
      if(imonsw(l2,mon).eq.0) then
        iwhy=1
        cwhy='Monthly Switch is off'
        goto 330
      endif  
c
c ---------------------------------------------------------
c		For a daily model set demand for beginning of season
      if(iday.eq.1 .and. imonsw(l2,mon).gt.0) then
        if (idy.lt.imonsw(l2,mon)) then
          iwhy=1
          cwhy='Daily switch Off'
          goto 330
        endif  
      endif  
c
c ---------------------------------------------------------
c		For a daily model set demand for end of season
      if(iday.eq.1 .and. imonsw(l2,mon).lt.0) then
        if (idy.gt.iabs(imonsw(l2,mon))) then
          iwhy=1
          cwhy='Daily switch Off'
          goto 330
        endif  
      endif  
      
c      
c ________________________________________________________
c                Step 4; Set pointer for destination reuse plan
c		                     ipUse = Reuse plan for return flows
      ipUse=ireuse(l2)
c      
c ________________________________________________________
c                Step 5; Set pointer for source plan
c	                 ipsource = Reuse plan for supply      
      np=iopsou(3,l2)
c
c _________________________________________________________
c
c                Step 6; Set source data Reservoir
c                       Source reservoir (nr), source account (iown),
c                       river station (iscd), & # downstream (ndnS)
      NR  =IOPSOU(1,l2)    

      if(iressw(nr).eq.0) then
        iwhy=2
        cwhy='Source Reservoir is off'
        goto 330
      endif  

      IOWN=NOWNER(NR)+IOPSOU(2,l2)-1

      iscd=IRSSTA(NR)
      ndnS=NDNNOD(iscd)
      cstaid1=cstaid(iscd)
c
c rrb 01/05/15; Check reservoir roundoff when entering routine
      call chekres(nlog, maxres, 0, 22, iyr, mon, nr,nowner,
     1             curown,cursto,cresid)
c
c               Calculate volume in reservoir
      RELALO=AMIN1(CURSTO(NR)-VOLMIN(NR),CUROWN(IOWN))
      RELALO=AMAX1(0.0,RELALO)
c
c               Change units and Limit to maximum river 
c               discharge (flowmax)
      alocfsR=RELALO/fac
      alocfsR=AMIN1(FLOMAX(NR)-RIVER(iscd),ALOCFSr)
      alocfsR= amax1(0.0,alocfsR)
c
c               Exit if nothing available
      if(alocfsR.lt.small) then
        iwhy=3
        cwhy='Supply Res is empty'
        goto 330
      endif  
c
c _________________________________________________________
c
c                Step 7; Set Source (Plan) data 
c                        that is required and checked in
c                        Oprinp when data is read
c
      IF(ifix(pon(np)).EQ.0) ioff=1
c
c rrb 2006/04/25; Add data in storage as part of the supply (acft)
cr    alocfsP = psuply(np)
c
c rrb 2008/09/22; Total supply in Psto2 (ACFT) includes psuply(np)
cx    alocfsP = psuply(np) + psto2(np)/fac
      alocfsP = psto2(np)/fac
      
      alocfsP=amax1(0.0, alocfsP)
      
      if(alocfsP.le.small) then
        iwhy=4
        cwhy='Plan Supply = 0'
        goto 330
      endif  
c
c _________________________________________________________
c
c                Step 8; Limit supply to the min of reservoir and plan
      alocfs=amin1(alocfsR, alocfsP)

c _________________________________________________________
c
c                Step 9; Set demand, etc for a Diversion destination
c
      ND  =IOPDES(1,l2)
      nd2 = nd
      ndx = nd
      nr2=0
    
      ndI=0
      ndP=0
      ndD=0
      ndR=0      
c     write(nlog,*) '  divRplR; nd ', nd  
c
c ---------------------------------------------------------
c                9a. Destination is a diversion
c rrb 2011/11/29; Update      
cx    if(nd.gt.0) then
      if(ndtype.eq.3) then
        ndD=nd
        nr2=0
        if(idivsw(nd).eq.0) ioff=2
      
        IUSE=NDUSER(ND)+IOPDES(2,l2)-1
        diveff1=diveff(mon,iuse)/100.        
        iuseX=iuse        
        
        IDCD=IDVSTA(ND)
        idcdD=idcd
        idcdX=idcd
        NDND=NDNNOD(IDCD)
        
        divreq1=divreq(iuse)
c
c               Determine Demand limited by supply
        DIVALO=AMIN1(DIVREQ(IUSE),divcap(Nd)-divmon(nd))
        divalo1=divalo
c        
c               If release type code is on
c                  Limit release to occur only if an IWR exists
c
c rrb 2021/04/18; Compiler warning
cx      ireltyp=amin0(iopsou(6,l2),ifix(effmax(nd)))
        ireltyp=min(iopsou(6,l2),ifix(effmax(nd)))
c
        divmax=divreq(iuse)

        if(ireltyp.gt.0) then 
          if(diwrreq(iuse).le.small) then
            divalo=0.0
          else
            divmax = diwrreq(iuse)/(float(ireltyp)/100.0)
            divalo=amin1(divalo, divmax)
          endif
        endif
cr
cr		Set supply based on depletion if icu0
cr      diveff1=diveff(mon,iuse)/100.
cr      if(icu.eq.1) then
cr        divalo=divalo/(diveff1)              
cr      endif
        
      endif
c
c _________________________________________________________
c               
c                Step 9b; Destination is a reservoir
c
c rrb 2011/11/29; Update 
cx    if (nd.lt.0) then
      if(ndtype.eq.2) then
        ndR=nd
cx      nrD=-nd
        nrD=nd
        ndX=nrD
cx      nr2=-nd
        nr2=nd
        if(iressw(nr).eq.0) ioff=3
        
cr      irow=nowner(nrD)+iopdes(2,l2)-1
c
c ---------------------------------------------------------
c rrb 2006/09/25; Allow multiple accounts where if iopdes(2,l2)
c                 is less than 0 it is all accounts and if it
c                 is greater than 0 it is just one account
        nro=1
        if(iopdes(2,l2).lt.0) then
          nro=-iopdes(2,l2)
          irow=nowner(nrD)
        endif
c 
        if(iopdes(2,l2).gt.0) then
          nro=1
          irow=nowner(nrD)+iopdes(2,l2)-1
        endif    
          
        iuseX=irow
c     
        idcd=irssta(nrD)
c
c rrb 2020/12/10; Correction
        idcdR=idcd
        idcdX=idcd
        ndnd=ndnnod(idcd)
c
c               Set demand
c
c ---------------------------------------------------------
c rrb 2006/09/25; Allow multiple accounts - Demand
        cursa=0.0
        do n=1, nro
          n1=irow+n-1
          cursa=cursa+(ownmax(n1)-curown(n1))
        end do
        
cr      divreq1=amin1(ownmax(irow)-curown(irow),
        divreq1=amin1(cursa,
     1                volmax(nrD)-cursto(nrD),
     1                tarmax(nrD)-cursto(nrD))/fac
        
        divreq1=amax1(0.0, divreq1)        
        DIVALO=divreq1
        divaloX=divalo
      endif
      
c
c _________________________________________________________
c rrb 2011/11/29; Update to allow an ISD destination               
c                Step 9b; Destination is an ISF
c
      if(ndtype.eq.1) then
        ndI=nd
        if(ifrrsw(ndI).eq.0) ioff=2
        
        IUSE=1
        iuseX=iuse
        
        IDCD=ifrsta(ndI)
        idcdI=idcd
        idcdX=idcd
        ndnd=NDNNOD(idcd)
        
        idcdX=idcdI
        ndndX=NDNNOD(idcdX)

        divreq0=flowrq(ndI)
        divreq1=flowrq(ndI)
        DIVALO=divreq1
        divaloX=divalo      
c
c rrb 2011/08/04; Instream flow reach    
        ib=ndnifb(ndI)
        ie=ndnifb(ndI) + ndnifs(ndI) -1  
        if(ioutIR.eq.1) then
          write(nlog,*) ' DivRplP; ndI, ib, ie', ndI, ib, ie
        endif     
       
cx      write(nlog,*) '  DivResP2;', ndI, flowrq(ndI)*fac  
      endif     
c
c _____________________________________________________________
c
c                Step 9c; Exit if no demand
      if(divalo.le.small) then
        iwhy=5
        cwhy='Demand or Capacity = 0'
        goto 330
      endif  
c
c _________________________________________________________
c
c		             Step 10. Exit if source res or source plan or
c                       destination diversion is off      
      if(ioff.gt.0) then
        iwhy=6
        cwhy='Plan or Div or Res is off'        
        write(nlog,*) ' divRplR; ioff', ioff
        goto 330
      endif
c
c _____________________________________________________________
c
c               Step 11a; Destination is through a carrier
c		               Adjust diversion location
      if(intern(l2,1).gt.0) then
c
c rrb 2020/12/12; Correction ncarry got reset in call SetcarL
cx      IDCD=IDVSTA(ncarry)
        ncarid=intern(l2,1)
        IDCD=IDVSTA(ncarid)
        
        idcdC=idcd
c       idcdX=idcd        
        NDND=NDNNOD(IDCD)
c
c rrb 2020/12/12; Correction ncarry got reset in call SetcarL
cx      divcarry=divcap(ncarry)-divmon(ncarry)  
        divcarry=divcap(ncarid)-divmon(ncarid)  
        write(nlog,*) ' DivRplR; ncarry, ncarid, idcd, idcdc'       
        write(nlog,*) ' DivRplR;', ncarry, ncarid, idcd, idcdc       
      endif      
c_____________________________________________________________
c
c rrb 2007/06/06; Add Carrier Loss             
c               Step 10; Process carrier limitations
      call SetCarL(nlog, icx, l2, fac, 
     1 maxopr,  maxdiv, intern, OprLossC,
     1 ncarry,  ncnum,  noprS,  internT, 
     1 OprEff1, DivCap, DivMon, DivCarry, alocfs)
c
c _____________________________________________________________
c
c                Step 11c; Exit if no carrier capacity
      if(divalo.le.small) then
        iwhy=7
        cwhy='Carrier Capacity = 0'
        goto 330
      endif  
c
c _____________________________________________________________
c
c                Step 12; Find minimum exchange potential from the 
c                       diversion node (idcd) to the Exchange point
c                       iopsou(6,l2)
c
      IMCD=Idcd
      ISS=Idcd
c
      ifound=0
      DO nx=1,NDND
        if (iss.eq.iExchPt) goto 110
        IF(AVAIL(IMCD).GT.AVAIL(ISS)) IMCD=ISS
        ISS=IDNCOD(ISS)
      end do
c
  110 pavail=amax1(0.0,avail(imcd))
c _________________________________________________________
c
c 		Step 13a Calculate diversion Based on Diversion
      if(icu .eq. 0) then
        DIVACT=amin1(pavail,divalo,alocfs)
        divact=amax1(0.0,divact)
        divactx=divact
c
cr        
        relact=-divact

        if(iout.eq.1) then
          write(nlog,342)pavail*fac, divalo*fac, alocfs*fac, divact*fac
        endif
      
        if(divact.le.small) then
          iwhy=8
          cwhy='Exchange potential = 0'
          goto 330
        endif
      endif  
c
c _________________________________________________________
c
c
c 		Step 13b Calculate diversion Based on Depletion

      if(icu .eq. 1) then
c
c                a. FIND THE MIN AVAIL FLOW DOWNSTREAM (avail(imcd))
cr      DIVACT=amin1(divalo,alocfs)
        DIVACT=amin1(divalo,alocfs/diveff1)
        divact=amax1(0.0,divact)
c
c               b. If Available flow < demand
c                  set the release (RELACT) to the difference
c                  (DIVACT - PAVAIL) or the depletion (divact*diveff)
        if(pavail .lt. divact) then
c
c rrb 05/05/12; limit diversion to amount in exchange reach
c		            release to meet depletion
c		            Concern if return flow timing drives system negative
          divact=pavail          
          relact=-1.*(divact*diveff(mon,iuse)/100.)
        else
c               c. If available flow >= demand (pavail>=divact)
c                  set release to the depletion (divact*diveff)
          relact=-1.*(divact*diveff(mon,iuse)/100.)
        endif
c
c               d. If iout=1 print detailed results
        if(iout.eq.1) then
          c = divact*diveff(mon,iuse)/100.0
          write(io99,390) 2, divact*fac, pavail*fac, relact*fac, c*fac
        endif
      endif
c
      iwhy=0
c
c _____________________________________________________________
c
c               Step 14; Add in source reservoir (and plan) release
c                        relact
c
        availr=avail(iscd)
        CALL TAKOUT(maxsta,AVAIL,RIVER,AVINP,QTRIBU,IDNCOD,
     1            relact,ndns,iscd)
        AVAIL(iscd)=AVAILR
c
c _____________________________________________________________
c
c               Step 15; Take out destination diversion or storage
c                        (divact)
c rrb 2011/11/29; Allow and ISF destination
        if(ndtype.eq.2 .or. ndtype.eq.3) then
        CALL TAKOUT(maxsta,AVAIL,RIVER,AVINP,QTRIBU,IDNCOD,
     1            DIVACT,NDND,IDCD)
        endif
c
c _________________________________________________________
c rrb 2011/11/29; Remove ISF from avail
c		            Step 16; Remove ISF from avail 
c                        Note adjust avail but not river 
      if(ndtype.eq.1) then
        issr=ifrsta(ndI)
        do i=ib,ie       
          if(ioutIR.eq.1) then
            write(nlog,*) 
     1        ' DivRplP; ndI, issr, avail, divact, avail-divact' 
            write(nlog,*) ' DivRplP; ', ndI, issr, 
     1        avail(issr)*fac, divact*fac, (avail(issr)-divact)*fac
          endif
          
          avail(issr)=avail(issr)-divact
          issr=idncod(issr)      
        end do  
      endif 
c
c _________________________________________________________
c
c		            Step 17; Calculate diversion with loss (divactL)
c		              and lost (OprLost)
c rrb 2007/06/06; Add loss        
      divactL=divact*OprEffT          
      OprLost=divact* (1.0-OprEffT)
c
c
c _________________________________________________________
c
c		            Step 16b; Add return flows if a diversion w/o reuse
c rrb 2011/11/29; Update to use ndtype     
cx      if(nd.gt.0 .and. ipuse.eq.0) then
        if(ndtype.eq.3 .and. ipuse.eq.0) then
          CALL RTNSEC(icx,DIVACTL,l2,IUSE,Idcd,nd,ieff2)       
        endif
c
c _________________________________________________________
c
c		            Step 17; Adjust a destination reuse
        
      if(ipUse.gt.0) then       
        if(nd2.gt.0) then         
          CALL RtnsecR(icx,divactL,l2,iuse,idcd,nd2,
     1         ieff2,ipUse)
c
c rrb 04/12/30; Qdiv(28 is the carried / exchanged water
c		Note works outside river system
          ipsta1=ipsta(ipUse)
c
c --------------------------------------------------------
c rrb 2020/12/07; Remove qdiv(28,xx) it is not used since 2010
cx        qdiv(28,ipsta1) = psuplyT(ipUse)     
        else
c
c		Reservoir Reuse          
          psuply(ipUse)=psuply(ipUse)+divactL
          psuplyT(ipUse)=psuplyT(ipUse)+divactL
c
c rrb 2006/01/01; Correction
          if(iplntyp(ipuse).eq.3 .or. iplntyp(ipuse).eq.5) then
            psto2(ipUse)=psto2(ipUse)+divactL*fac          
          endif  
          
          ipsta1=ipsta(ipUse)
c --------------------------------------------------------
c rrb 2020/12/07; Remove qdiv(28,xx) it is not used since 2010
cx          qdiv(28,ipsta1) = psuplyT(ipUse)                 
        endif  
      endif
c
c _____________________________________________________________
c
c                Step 18; Udate
c
c		             18a. Update a diversion Destination
c             
c rrb 2011/11/29; Update
cx    if(nd.gt.0) then
      if(ndtype.eq.3) then
        USEMON(IUSE)=USEMON(IUSE)+DIVACT
        DIVREQ(IUSE)=DIVREQ(IUSE)-DIVACT
        DIVMON(ND  )=DIVMON(ND  )+DIVACT
c
c rrb 2007/06/06; Add Loss in SetqdivC    
c		             18a. Destination is a diversion 
c ------------------------------------------------------
c rrb 2020/12/07; Correction should be 
c                 qdiv(26,idcdd) = From River by Other not 
c                 qdiv(20,idcdd) = From Carrier by Other       
cx      qdiv(20,idcdd)=qdiv(20,idcdd)+divactL
        if(ncarry.eq.0) then
          qdiv(26,idcdd)=qdiv(26,idcdd) + divact
          qdiv(38,idcdd)=qdiv(38,idcdd) + divact
        endif
c
c ---------------------------------------------------------

c		             18b. Destination is also the carrier
        if(idcd.eq.idcdc) then
c ---------------------------------------------------------
c rrb 2020/12/07; Correction qdiv(26,idcdd) is set in setqdiv?
cx        qdiv(26,idcd)=qdiv(26,idcd)+divact
          qdiv(18,idcd)=qdiv(18,idcd)+divactL  
          qdiv(33,idcd)=qdiv(33,idcd)+OprLost  
        endif  
        
        if(iout.eq.1) 
     1    write(nlog,*) '  DivRplR;', idcdd, idcd, idcdc,
     1    divact*fac, qdiv(20,idcdd)*fac, qdiv(33,idcdd)*fac,              
     1    qdiv(26,idcd)*fac, qdiv(18,idcd)*fac, qdiv(33,idcdd)*fac
        
      endif  
c      
c -------------------------------------------------------------
c		             18c. Update a destination reservoir
c
c rrb 2011/11/29; Update
cx    if(nd.lt.0) then
      if(ndtype.eq.2) then
        divaf=divact*fac
c
c rrb 2007/06/06; Add Loss
        divafL=divaf*OprEffT        
        cursto(nrD)=cursto(nrD)+divafL
        
cr      curown(irow)=curown(irow)+divaf
c
c ---------------------------------------------------------
c rrb 2006/09/25; Allow multiple accounts - Allocate
c		              Note:
c		              iResT1=0 distributes based on ownership ratio
c		              nrown1=number of accounts in this reservoir
c		              iown = first account associated with this reservoir  
c		              icx  = subrouine calling accou.for       
c		              ia   = account to adjust
      
        nrX=nrD
        iResT1=0
        nrown1=nro
        iownX=irow
        icx=133
        
        if(ncarry.eq.0) then
          ia=18
        else
c
c
c rrb 2020/12/10; Correction 2 is by Priority & 4 is by Other
cx        ia=2
          ia=4
        endif  
        
        cresid1=cresid(nrX)
c        
        call accou(maxacc, maxown, nrX, ownmon, curown, accr, ia, 
     1    ownmax, iownX, nrown1, cursa, divafL, iResT1, icx, cresid1)

c
c ---------------------------------------------------------
c
c		             18d. Update carrier to a reservoir destination
c
c ---------------------------------------------------------
c rrb 2020/12/12; Correction source is a res or plan (not priority)
c	                    qres(2,ix)  From carrier to by Priority
c                     qres(4,ix)  From carrier by Other
c                     qres(18,ix) From River by Exchange, ... (Other)
c
c                     qdiv(20     From Carrier by Other (Sto, Exc ...)
c                     qdiv(21     From River by Other (Sto, Exc ...)
c                     qdiv(38               Report as carried water  
cx        if(ncarry.eq.0) then
cx          qres(18,nrD)=qres(18,nrD)+divafL
cx        else
cxc
cxcx        qres(2,nrD)=qres(2,nrD)+divafL
cx          qres(4,nrD)=qres(4,nrD)+divafL
cx        endif  
cx        
        if(ncarry.eq.0) then
          qres(18,nrD)=qres(18,nrD)+divafL
          
          qdiv(21,idcd)=qdiv(21,idcd) + divact
          qdiv(38,idcd)=qdiv(38,idcd) + divact
        else
          qres(4,nrD)=qres(4,nrD)+divafL
          
          qdiv(21,idcdC)=qdiv(21,idcdC) + divact
          qdiv(38,idcdC)=qdiv(38,idcdC) + divact
 
          qdiv(20,idcdR)=qdiv(20,idcdR) + divact
          qdiv(38,idcdR)=qdiv(38,idcdR) + divact
        endif          
c
c               Check reservoir roundoff when exiting routine
        call chekres(nlog, maxres, 1, 22, iyr, mon, nrD,nowner,
     1               curown,cursto,cresid)
     
      endif
c
c -------------------------------------------------------------
c rrb 2011/11/29; 
c		             18e. Update a destination ISF
      if(ndtype.eq.1) then
        flowrq(ndI)=amax1(0.0, flowrq(ndI) - divactL)
c
c rrb 2011/08/04; Instream flow reach
        do i=ib,ie
          florqr(i)=florqr(i)-divact
          qdivr1=qdivr(i)
          qdivr(i)=qdivr(i)+divact
        end do          
c
        qdiv(30,idcd)=qdiv(30,idcd) + DIVACT
        qdiv(38,idcd)=qdiv(38,idcd) + divact
      endif       
      
c      
c _________________________________________________________
c                Step 19; Qdiv and Carrier for all destinations
c  
      if(iout.eq.1) then
        write(nlog,*) '  DirectEx; Call SetCarry'
        call flush(nlog)
      endif  
c      
c ---------------------------------------------------------
c		             19a; Set Qdiv for the carrier
c rrb 2007/06/06; Add loss      
      write(nlog,*) ' DivRplR #3a; qdiv(20,idcd)', qdiv(20,idcd)*fac
      
      
      if(ncarry.gt.0) then  
        call setQdivC(
     1    nlog, ncarry, ncnum, nd, nd2, l2, idcd, idcdX, idcdC,
     1    nriver, divact, TranLoss, EffmaxT1, 
     1    fac, maxsta, maxdiv, maxqdiv, maxopr, 
     1    intern, idvsta, qdiv, divmon, 
     1    maxrtnw, maxdivw, OprEff1, ipuse,  
     1    pctlosPP, rlossP, oprLossc,internT,
     1    icx, corid(l2))
      endif
     
c
c -------------------------------------------------------------
c		             Step 20 Update source
c                20a. Source is a plan
      psuply(np)=amax1(0.0, psuply(np) +relact)
c
c rrb 2006/01/01; Correction for a reservoir plan
      if(iplntyp(np).eq.3 .or. iplntyp(np).eq.5) then
        psto2(np)=amax1(psto2(np)+relact*fac, 0.0)                
      endif  
c
c ---------------------------------------------------------
c                20b. Source is a reservoir (nr) data
      ACTACF=RELACT*fac
      CURSTO(NR  )=CURSTO(NR  )+ACTACF
      PROJTF(NR  )=PROJTF(NR  )-RELACT
      CUROWN(IOWN)=CUROWN(IOWN)+ACTACF
c
      QRES(8,NR)=QRES(8,NR)-ACTACF
      accr(8,iown) = accr(8,iown)-actacf
c
c ---------------------------------------------------------
c rrb 2020/12/12; Set source for reservoir release  
cx    if(ncarry.gt.0) then
cx      qdiv(30,iscd)=qdiv(30,iscd)+DIVACT
cx    endif  
c  
      if(ncarry.eq.0) then
        qdiv(30,iscd)=qdiv(30,iscd)-DIVACT
        qdiv(38,iscd)=qdiv(38,iscd) + divact
      else
        qdiv(26,iscd)=qdiv(26,iscd)-DIVACT
        qdiv(38,iscd)=qdiv(38,iscd) + divact
      endif    
c
c ---------------------------------------------------------
c                20c. Update data to be passed out of this routine. 
c                  Note divact .NE. relact if release for depletion 
      divactx=divact
      divacty=divact
c
c
 330  continue
c
c ---------------------------------------------------------
c rrb 2011/11/29 
c                20d. Update shortage
cx    if(nd.gt.0 .and. (divact+small).lt.divalo) ishort = 1
      if((divact+small).lt.divalo) ishort = 1
c
c ---------------------------------------------------------
c                20e. Update operational rule data
c		                  to amount used from supply (relact) 
c                     not amount diverted (divact)
c		                  Note this is required for consistency and
c		                  for plan output to be correct (it uses 
c                     *.xop output)
cr    divo(l2)=divo(l2)+divact
      divo(l2)=divo(l2)-relact
      
c
c _____________________________________________________________
c
c                Step 21; Final printout before exit
c
      if(iout.ge.1 .and. iw.eq.ioutiw) then
c
c                21a. FIND THE MIN AVAIL FLOW DOWNSTREAM (avail(imcd))
         if(idcd.gt.0) then
           iss=IDcd
           NDNDS=NDND
c
c rrb 2021/05/02; Runtime error tracking
cx         CALL DNMFSO(maxsta, avail,idncod,iSS,ndndS,imcd)
           CALL DNMFSO2(maxsta,avail,idncod,iSS,ndndS,imcd,cCallBy)
           avail1=avail(imcd)
           qdiv29=qdiv(29,idcd)
c 
c rrb 2020/12/10; Detailed output 
           FrCarOth = qdiv(20,idcd)  
           FrRivOth = qdiv(21,idcd) + qdiv(23,idcd) + qdiv(26,idcd) +
     1                qdiv(29,idcd) + qdiv(30,idcd) + qdiv(31,idcd)
         endif
c
c rrb 2020/12/08; Moved from above
c		             21b. Detailed Header            
         ncallX=ncallX+1
         if(ncallX.eq.1) then
           write(nlog,270) corid(l2),cdestyp, ccarry, cpuse,
     1                     cDivTyp(l2)
         endif  
c
c                21c. Print detailed data   
         if(iday.eq.0) then
           write(nlog,280) 'DivRplR    ',
     1       iyrmo(mon),   xmonam(mon), idy, iwx, iw, l2, ndX, iuseX, 
     1       icu, diveff1*100., 
     1       divreq1*fac,  alocfsR*fac, alocfsP*fac, alocfs*fac, 
     1       divaloX*fac,  pavail*fac,
     1       divcarry*fac, abs(relact*fac), divact*fac,  iwhy, cwhy,
     1       imcd,  idcd, idcdC,
     1       FrCarOth*fac, FrRivOth*fac
     
cx             qdiv(20,idcd)*fac,
cx     1       qdiv(21,idcd)*fac, qdiv(23,idcd)*fac, qdiv(26,idcd)*fac,
cx     1       qdiv(29,idcd)*fac, qdiv(30,idcd)*fac, qdiv(31,idcd)*fac
         else
           write(nlog,282) 'DivRplR    ',
     1      iyrmo(mon),   xmonam(mon), idy, iwx, iw, l2, ndX, iuseX, 
     1      icu, diveff1*100., 
     1      divreq1*fac,  alocfsR*fac, alocfsP*fac, alocfs*fac,
     1      divaloX*fac,  pavail*fac,
     1      divcarry*fac, abs(relact*fac), divact*fac,  iwhy, cwhy,
     1      imcd,  idcd, idcdC, FrCarOth*fac,      FrRivOth*fac
     
cx     ,      qdiv(20,idcd)*fac, 
cx     1      qdiv(21,idcd)*fac, qdiv(23,idcd)*fac, qdiv(26,idcd)*fac,
cx     1      qdiv(29,idcd)*fac, qdiv(30,idcd)*fac, qdiv(31,idcd)*fac
        endif
cr      if(divact*fac.gt.small .and. avail(imcd)*fac.le.small)
cr   1  write(nlog,*) '*****' 
      endif
c
c _____________________________________________________________
c               
c               Step 22; Check Entire Avail array out
      call chekava(29, maxsta, numsta, avail, subtypX)
      if(iouta.gt.0) write(nlog,*) '  divRplR; OK going out'
c
c _____________________________________________________________
c
c                Step 23; Return
      return
c _________________________________________________________
c               Formats
 270    format(/, 
     1  '  DivRplR (Type 33); Operation Right ID = ', a12,
     1  ' Destination Type = ', a12,
     1  ' Carrier (Y/N) = ',a3, ' Reuse (Y/N) = ', a3, 
     1  ' Diversion Type ', a12/    
     1  '  divRplR      Iyr  Imo  Day Iter  iwx   l2 ndX iuseX Dep?',
     1  ' DivEff1 Divreq1 AlocfsR AlocfsP  Alocfs divaloX  Pavail',
     1  ' Divcary  RelAct  DIVACT',
     1  '    iwhy cwhy                     imcd idcd idcdC'
     1  ' FrCarOt FrRivOt',/
cx     1  ' qdiv(20 qdiv(21 qdiv(23 qdiv(26 qdiv(29 qdiv(30 qdiv(31',/
     1  '  ___________ ____ ____ ____ ____ ____ ____ ____ ____ ____', 
     1  ' _______ _______ _______ _______ _______ _______ _______',
     1  ' _______ _______ _______',
     1  ' _______ ________________________ ____ ____ ____')
cx     1  9(' _______'))
 280   format(1x,a12, i5, 1x,a4, 7i5, 10f8.1, i8, 1x,a45, 3i5, 20f8.1)
 282   format(1x,a12, i5, 1x,a4, 7i5, 10f8.3, i8, 1x,a45, 3i5, 20f8.3)

cx301   format(/,60('_'),/,
cx   1   '  divRplR;  iyr  mon iteration ', 3i5,/
cx   1   '  divRplR;   iw iout    ichk99 ', 3i5)

 342    format(
     1     '  divRplR; Diversion Limit;',
     1     '  pavail  divalo  alocfs  divact',/
     1     '                          ', 20f8.2)
  390      format(
     1       '  divRplR; Release for Depletion Data;',/
     1       '                  #  divact  pavail  relact      CU',/
     1       '           ', i8, 20f8.2)
     
c
c _____________________________________________________________
c
c		Error Processing
 9999 write(6,1050) 
      write(nlog,1051) 
      
 1050 format('    Stopped in divRplR',/,
     1       '    See the *.log file')
 1051 format('    Stopped in divRplR')
      write (6,*) 'Stop 1'
      call flush(6)
      call exit(1)
      stop 
      END
