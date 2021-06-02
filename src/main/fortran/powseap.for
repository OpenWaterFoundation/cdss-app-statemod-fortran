c powseap - Type 29 operating rule, Plan spill
c           It simulates a type 29 operating rule that
c           makes a plan releases (spill) from a plan or a reservoir and a plan.
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
      subroutine PowseaP(iw,l2,divact,ncallX)
c
c _________________________________________________________
c	Program Description
c
c	 Type 29; Plan spill
c       PowseaP; It simulates a type 29 operating rule that
c                makes a plan releases (reset) from:
c                1) a reservoir and a plan or
c                2) a WWSP User plan (type 14) not tied to a reservoir  
c
c          Passing arguments:
c	         iw              the index of the water rights loop in
c                          execut.for where this routine is called
c                          used as index in water rights arrays
c          l2              the index of the operating rule loop in
c                          execut.for where this routine is called
c                          used as index in operating rule arrays
c          divact          the diversion or reservoir release amount
c                          that requires reoperation
c          ncallx          a counter for the number of times this
c                          routine has been called
c
c          Global variables:
c          iopsou(1,l2)    the integer INDEX of the source 1 structure in the
c                           list of structures of that type (e.g. reservoirs or plans)
c                          the ID of the structure is found in the
c                           opr input file, source id field, ciopso(1)
c                          the ID ciopso(1) is converted to the INDEX iopsou(1,l2)
c                           with a call to oprfind routine (the iops1 arg)
c                          Supply reservoir index or ReUse plan index or Acct plan index
c                          > 0 Source 1 is a reservoir
c                          < 0 Source 1 is a plan
c          iopsou(2,l2)    the integer value of the source 1 account
c                           field, iopsou(2,1), in the opr input file
c                          integer index of Supply reservoir account
c                          or ReUse account (0 if not applicable)
c          iopsou(3,l2)    the integer INDEX of the source 2 structure in the
c                           list of structures of that type (e.g. plans)
c                          the ID of the structure is found in the
c                           opr input file, source id field, ciopso(2)
c                          the ID ciopso(2) is converted to the INDEX iopsou(3,l2)
c                           with a call to oprfind routine (the iops1 arg)
c                          > 0 => Source 2, ciopso(2), is a plan ID
c                          Source 2, ciopso(2) = "NA" if not applicable
c          iopsou(4,l2)    the integer value of the source 2 account
c                           field, iopsou(4,1), in the opr input file
c                          always = 0
c	         iopsou(5,l2) 	  if > 0 it is the integer INDEX of the
c                            operating rule that will have its
c			                       monthly and annual limits adjusted
c                            ...many more need to be documented...
c
c          iopdes(1,l2)    Spill location
c                          if > 0 spill location = nspill
c                          if = 0 spill at reservoir or plan location
c                          if < 0 no spill; just reset to zero.
c
c          nspill          see above for iopdes(1,l2) > 0
c
c          qdiv(18  	      Carrier passing thru a structure
c		       qdiv(28         Carried, Exchange or Bypass (column 11)
c                          Released from a reuse plan or Admin plan
c                          !! Not currently used in outmon.for
c		       qdiv(36         Water released to the river (report as
c			                     return flow).
c          qdiv(37         Water released to the river (report as
c                          a release (negative diversion) that is
c                          subtracted in outmon.f
c          qdiv(38         Carried water not used to calculate
c                          River Divert in Outmon
c                  
c
c          Local variables:
c	         nr  > 0         Reservoir pointer
c	         npS > 0         Source 1 or Source 2 plan pointer
c	         np2 > 0       	 Source 2 plan pointer
c                          np2 = iopsou(3,l2)
c
c _________________________________________________________
c       Update History
c
c
c rrb 2021/04/18; Compiler warning
c
c rrb 2021/02/14; Revised to let iopsouR(L2) control the source
c                  type.  Specifically iopsou(1,k) is positive
c                  for both a reservoir and plan source.
c
c rrb 2019/05/26; Revised detailed output to report a physical
c                  spill(cspill = Yes) or a reset (cspill = No) 
c
c rrb 2019/04/20; Revised to recognize a WWSP Supply plan is a
c                   type 14 and a WWSP User Plan is a type 15
c
c rrb 2018/10/11; Revised to reset a WWSP plan when source 1
c                 is a WWSP plan (type 14) and varible ciopde 
c                 (iopdes(1,l2) = -1 (no reservoir spill)
c
c rrb 2018/10/11; Revised to simulate spill from a reservoir
c                 as source 1 and a WWSP plan (type 14) as the 
c                 second source
c rrb 2007/07/03; Revised to adjust monthly and annual limits
c		  
c rrb 2006/04/05; Allow source 3 to be a reservoir and spill 
c		              from both a plan and a reservoir
c rrb 2005/01/07; Copy Powsea (spill release) and update accordingly
c _________________________________________________________
c	Dimensions
c
      include 'common.inc'
      character cwhy*48, cdestyp*12, ccarry*3, cpuse*3, cstaid1*12,
     1          rec12*12, cTandC*3, cstaSP*12, cspill*3,
     1          csoutyp*12
      
c
c _________________________________________________________
c
c
c rrb 2021/04/18; Compiler warning
      n1=0
      ioutiw=0
      iscdp=0
      
c		              iout = 0 No detailed printout
c		                   = 2 Summary printout
c                 ioutQ= 1 Print detailed Qdiv results at nspill
c                        2 Print detailed Qdiv results at all nodes
c                 ioutA= 1 Print avail before & after Takout
      iout=0
      ioutQ=0
      ioutA=0
      rec12=rec12
c
      icx=29
      
      if(ichk.eq.94) then
        write(nlog,*) ' PowseaP; Type 29'
        iout=1
      endif 
      
      if(ichk.eq.129) iout=2
      if(corid(l2).eq. ccall) ioutiw=iw  
      
cx      if(iout.ge.1 .and. ncallx.eq.0) then      
      if(iout.ge.1 .and. ncallx.eq.0 .and. ioutiw.eq.iw) then
        write(nlog,102) corid(l2)
 102    format(/, 72('_'),/ '  PowSeaP; ID = ', a12)
      endif             
  
      divact = 0.0
      iw = iw
c
c rrb 98/08/10
      small=0.001
      small2=0.1
c
c rrb 98/03/03; Daily capability
      if(iday.eq.0) then
        fac=mthday(mon)*factor
      else
        fac=factor
      endif
c
c
c rrb 2014/01/15; Print Qdiv data
      if(ioutQ.gt.0) then
        write(nlog,*) ' '
        write(nlog,*) ' PowSeaP  in; Qdiv report'
        write(nlog,'(4x, 39i8)') (j, j=1,39)
c
c rrb 2015/10/10; Detailed output
        nspill  =Iopdes(1,L2)
        if(ioutQ.eq.1 .and. nspill.gt.0) then
          write(nlog,*)' PowseaP; nspill=', nspill, cstaid(nspill)
          write(nlog,'(i5, 39f8.0)')
     1      i, (qdiv(nspill,i)*fac, j=1,39)
        endif
        if(ioutQ.eq.2) then
          do i=1, numsta
            write(nlog,'(i5, 39f8.0)') i, (qdiv(j,i)*fac, j=1,39)
          end do
        endif
      endif
            
      iwhy=0
      cwhy='NA'
      cdestyp='NA'
      csoutyp='NA'
      ccarry='No'
      cpuse='No'
      cTandC='No'
      cstaid1='NA'
      cspill='Yes'
      
      npS=0
      np2=0

      ravcfs=-1./fac     
      ravcfs1=-1./fac     
      ravcfs2=-1./fac     
      ravcfs3=-1./fac     
      ravcfs4=-1./fac     
      
      OprmaxM1=-1.0
      OprmaxM2=-1.0
c
c rrb 02/10/25; Allow monthly on/off switch
      if(imonsw(l2,mon).eq.0) then
        iwhy=1
        cwhy='Monthly switch is off'
        goto 120
      endif  
c
c ---------------------------------------------------------
c		For a daily model set demand for beginning of season
      if(iday.eq.1 .and. imonsw(l2,mon).gt.0) then
        if (idy.lt.imonsw(l2,mon)) then
          iwhy=1
          cwhy='Daily switch Off'
          goto 120
        endif  
      endif  
c
c ---------------------------------------------------------
c		For a daily model set demand for end of season
      if(iday.eq.1 .and. imonsw(l2,mon).lt.0) then
        if (idy.gt.iabs(imonsw(l2,mon))) then
          iwhy=1
          cwhy='Daily switch Off'
          goto 120
        endif  
      endif  

c
c_____________________________________________________________
c               Step 1.5; Set Destination Data to allow the user to
c                         control where the spill enters the stream
c
c rrb 2014-04-26
        nspill  =Iopdes(1,L2)     
        cstaSP ='NA          '
        
        if(nspill.gt.0) then
          NdSP=NDNNOD(nspill)     
          cstaSP = cstaid(nspill) 
c
c rrb 2019/08/25; Set Destination type
          cdestyp=cstaSP
c
          if(iout.eq.1) then
            write(nlog,*) ' '  
            write(nlog,*) ' PowseaP;', nspill, ndSP, cstaSP
          endif
c
c rrb 2019/05/26; Print physical spill to detailed output
        else
          cspill='No '          
        endif         
c      
c _________________________________________________________
c
c		Step 2; Set Source Data (a reservoir or a plan)
c              Find reservoir (nr), owner (iown), river location (iscd)
c                and # of downstream nodes (ndns)
c              Note the source is a reservoir when NR > 0
c              Note the source is a plan when NR < 0 that sets NPS 
c              Note the source is a reservoir with a plan when NR>0 
c                and iopsou(3,l2) > 0
C
c rrb 2021/02/14; Clean up
cx      NR = IOPSOU(1,L2)      
cx      if(nr.lt.0) npS=-nr
cxc
cxc rrb 2019/08/25; Set the source type
cx      if(nr.gt.0) then
cx        csoutyp='Reservoir   '
cx      else
cx        csoutyp='Plan        '
cx      endif
c
c ---------------------------------------------------------
c rrb 2019/08/25; Set source 1  & check its a 
c                 reservoir (2) or plan (7)
      ns = iopsouR(l2)
      iok=1
      if(ns.eq.2) then
        csoutyp='Reservoir   '
        nr = iopsou(1,L2)
        nps = -1
        iok = 0
      endif
      
      if(ns.eq.7) then
        csoutyp='Plan        '   
        nps = iopsou(1,L2)
        nr = -1
        iok = 0
      endif
      
      if(iok.eq.1) then
        write(nlog,170) ns
        goto 9999
      endif
c
c 
c ---------------------------------------------------------
c               Set Source 2      
      NP2 = iopsou(3,l2)
      if(iout.eq.1) write(nlog,*) '  PowseaP; nr, npS, np2',
     1   nr,npS,np2
c
c ---------------------------------------------------------
c
c		2a; Exit if source 1 reservoir is off      
c
      if(nr.gt.0) then
        if (iressw(nr).eq.0) then
          iwhy=2
          cwhy='Reservoir source is off'
          goto 120
        endif
      endif
c
c
c ---------------------------------------------------------
c
c		2b; Exit if source 1 plan is off            
      IF(nps.gt.0) then
        if (pon(npS).LE.small) then
          iwhy=3
          cwhy='Source 1 Plan is off'
          Goto 120
        endif
      endif  
c
c ---------------------------------------------------------
c
c		2c; Exit if source 2 plan is set (np2 = iopsou(3,l2) > 0 and 
c       the plan is off (pon(np2) < 0           
      IF(np2.gt.0) then
        if (pon(np2).LE.small) then
          iwhy=4
          cwhy='Source 2 Plan is off'
          Goto 120
        endif
      endif    
c      
c _________________________________________________________
c
c		Step 3; Source 1 is a reservoir
      if(nr.gt.0) then
        
        IOWN=NOWNER(NR)+IOPSOU(2,L2)-1
        ISCD=IRSSTA(NR)
        NDNS=NDNNOD(ISCD)
        cstaid1=cresid(nr)
C
c
c ---------------------------------------------------------
c
C        	3b. CALCULATE VOLUME AVAILABLE FROM RESERVOIR 
c                   (resval - af, ravcfs - cfs)
C
c rrb 02/05/97; Allow release from all accounts
        if(iopsou(2,l2).gt.0) then
          RESVAL=AMAX1(AMIN1(CURSTO(NR),CUROWN(IOWN)),0.)
        else
          resval=amax1(cursto(nr),0.0)
        endif
        
        RAVCFS=RESVAL/fac
        ravcfs1=ravcfs
        
        IF(RAVCFS.LE.small) then
          iwhy=5
          cwhy='Source 1 Reservoir storage is zero'
          Goto 120
        endif  
c
c ---------------------------------------------------------
c
c		3c; Compare max release (flomax) to flow in river (river)
c
        FLOAVL=AMAX1(FLOMAX(NR)-RIVER(ISCD),0.)
        ravcfs=amin1(ravcfs, floavl)
        ravcfs2=ravcfs        
        
        IF(FLOAVL.LE.small) then
          iwhy=6
          cwhy='Source 1 Reservoir Maximum Release is zero'        
          Goto 120        
        endif  
        
      endif
c _________________________________________________________
c
c		Step 4; Source is a Plan
c rrb 2018/10/19; Clean up
cx    if(nr.lt.0) then
      if(npS.gt.0) then
c
c rrb 2021/02/14; clean up
cx      npS=-nr
        np2=0
        iscd=ipsta(npS)
        iscdP=iscd
        
        NDNS=NDNNOD(ISCD)        
        cstaid1=pid(npS)        
        
        psuply1=psuply(npS)
        iplntyp1=iplntyp(npS)   
c 
c ---------------------------------------------------------
c rrb 2018/10/19; Allows source 1 to be a WWSP plan
cx        if(iplntyp1.eq.3 .or. iplntyp1.eq.5) then
cx          psuply1= psto2(npS)/fac
cx        endif     
c 
c rrb 2019/04/20; Revise for a WWSP Supply (type 14) and 
c                 WWSP User (type 15)  
cx      if(iplntyp1.eq.3 .or. iplntyp1.eq.5 .or. iplntyp1.eq.14) then
        if(iplntyp1.eq.3 .or. iplntyp1.eq.5 .or. iplntyp1.eq.14 .or.
     1     iplntyp1.eq.15) then
          psuply1= psto2(npS)/fac
        endif
c        
        ravcfs=psuply1
        ravcfs3=ravcfs
c
c ---------------------------------------------------------        
c        
c		3b; Exit if Plan Source 1 is zero
        if(iout.eq.1) then
            write(nlog,*) '  PowseaP;',
     1      'nr, npS, np2, iplntyp1,',
     1      ' psuply(npS), ravcfs3, ravcfs'
          write(nlog,*) '  PowseaP;',
     1      nr,  npS,np2, iplntyp1, 
     1      psuply1*fac, ravcfs3*fac, ravcfs*fac
        endif

        IF(ravcfs.LE.small) then
          iwhy=7
          cwhy='Source 1 Plan Supply is zero'        
          Goto 120        
        endif  
c
c ---------------------------------------------------------        
c       Endif for source is a plan (nSp > 0)       
      endif  
c
c _________________________________________________________
c
c rrb 2006/04/05; 
c		Step 4; Set Plan Source 2 Data
c           WARNING; npS gets reset to np2 to simplify updating
      if(np2.gt.0) then
        npS=np2
        iscdP=ipsta(npS)
        NDNS2=NDNNOD(ISCD)        
        
        psuply1=psuply(npS)
        iplntyp1=iplntyp(npS)        
c
c 
c rrb 2019/04/20; Revise for a WWSP Supply (type 14) and 
c                 WWSP User (type 15)  
cx      if(iplntyp1.eq.3 .or. iplntyp1.eq.5 .or.iplntyp1.eq.14) then
        if(iplntyp1.eq.3 .or. iplntyp1.eq.5 .or.iplntyp1.eq.14 .or.
     1       iplntyp1.eq.15) then
          psuply1= psto2(npS)/fac
        endif  
        
        ravcfs4=psuply1
        ravcfs=amin1(ravcfs, psuply1)
c
c ---------------------------------------------------------        
c
c		4b; Exit if Plan Source 2 is zero
        IF(ravcfs.LE.small) then
          iwhy=8
          cwhy='Source 2 Plan Supply is zero'        
          Goto 120        
        endif  
        
        if(iout.eq.1) write(nlog,*) '  PowseaP; nr, npS, np2 ravcfs4',
     1    nr,npS,np2, ravcfs4*fac
        
      endif  
c _________________________________________________________
c
c		            Step 5; Set release
      divact=amax1(0.0, ravcfs)
C
c _________________________________________________________
c
c		            Step 6; ADD RES. or Plan RELEASE DOWNSTREAM
c		                    Note ndns and iscd are set above
c                       depending on the supply source
c
c rrb 2014-05-05; allow spill to occur downstream of plan when nspill>0
c rrb 2014/11/24 Check Avail         
      if(ioutA.eq.1) then    
        write(nlog,*) ' '   
        write(nlog,*) ' PowseaP;', nspill, iscd,ndSP,cstaSP,divact*fac
        ifirst=0
        nchkA=1
        call ChkAvail2(nlog, ifirst, icx, nchkA, maxsta, numsta, 
     1       fac, avail)
      endif   
c
c ---------------------------------------------------------
c
c rrb Allow spill location to be set if nspill = iopdes(1,l2) > 0

c ---------------------------------------------------------
c rrb 2018/10/19; Allow nspill to be -1 when the source is a WWSP
c                 plan that is being reset.
      if(nspill.lt.0) then  
        TEMP=0.0    
      endif
c
c ---------------------------------------------------------
      if(nspill.eq.0) then
        TEMP=-DIVACT   
        CALL TAKOUT(maxsta, AVAIL ,RIVER ,AVINP ,QTRIBU,IDNCOD,
     1              TEMP  , NDNS,  ISCD  )
c
c rrb 2015/08/23; If the spill location has not been specified, 
c                 revise to not adjust avail at the reservoir itself
c                 This is consistent with a type 9 reservoir spill    
        AVAIL (ISCD)=AVAIL (ISCD)-DIVACT 
      endif
c
c ---------------------------------------------------------
c rrb 2018/10/19; Allow nspill to be -1 to indicate no spill; only
c                 a reset of the plan    
cx    else   
      if(nspill.gt.0) then  
        TEMP=-DIVACT    
        CALL TAKOUT(maxsta, AVAIL ,RIVER ,AVINP ,QTRIBU,IDNCOD,
     1              TEMP  , Ndsp,  nspill  )
      endif
c
c rrb 2014/11/24 Check Avail         
      if(ioutA.eq.1) then
        call ChkAvail2(nlog, ifirst, icx, nchkA, maxsta, numsta, 
     1       fac, avail) 
      endif           
c
c _________________________________________________________
c
c		            Step 7; REDUCE SUPPLY RESERVOIR STORAGE BY RELEASE 
c                       (divact)
      if(nr.gt.0) then
        RELAF=DIVACT*fac
        cursto1=cursto(nr)
        CURSTO(NR) = CURSTO(NR)-RELAF
        PROJTF(NR) = PROJTF(NR)+DIVACT
C
        POWREQ(NR) = POWREQ(NR)-RELAF
        POWREL(NR) = POWREL(NR)+DIVACT
c
c ---------------------------------------------------------        
c
c		7b; Distribute to account assigned (iopsou>0) or
c                   based on current storage in all accounts
c                   (iopsou=0)
        if(iopsou(2,l2).gt.0) then
          CUROWN(IOWN)=CUROWN(IOWN)-RELAF
          accr(19,iown) = accr(19,iown) + relaf
        else
          ct=0.0
          iown=nowner(nr)-1
          if(iopsou(2,l2).eq.0) then
            nrown1=nowner(nr+1)-nowner(nr)
          else
c           nrown1=abs(iopsou(2,l2))
            write(nlog,111) iopsou(2,l2)
            goto 9999
          endif
c
c ---------------------------------------------------------        
c
c		            7c; Detailed output
          if(iout.eq.1) then        
            write(nlog,140) nr, iown, nowner(nr+1), nowner(nr), nrown1
            write(nlog,150) n1, relaf, curown(n1), cursto1, c, ct
          endif
c
c
c ---------------------------------------------------------        
c
c		            7d; Distriubute to accounts
          do 112 n=1,nrown1
            n1=iown + n
            c=(curown(n1)/cursto1)*relaf
            curown(n1)=curown(n1)-c
            accr(19,n1) = accr(19,n1) + c
            ct=ct+c
            
            if(iout.eq.1) then
              write(nlog,160) n1, relaf, curown(n1),cursto1, c, ct
            endif
 112      continue
c
c ---------------------------------------------------------        
c
c		            7e; Release Check 
c         if(ABS(ct-relaf).gt.0.1) then
          if(ABS(ct-relaf).gt.small2) then
            write(6,130) ct, relaf, ct-relaf, small2
            write(nlog,130) ct, relaf, ct-relaf, small2
          endif
        endif
c
c
c ---------------------------------------------------------        
c
c		            7f; Roundoff check
        call chekres(nlog,maxres, 1, 9, iyr, mon, nr,nowner,
     1                curown,cursto,cresid)
        
      endif
c _________________________________________________________
c
c		            Step 8; Source is a Plan, adjust supply
c                       Note npS was set to np2 in step 4 (above)
c
      if(nr.le.0 .or. np2.gt.0) then
        psuply(npS)=amax1(0.0, psuply(npS) - divact)
c
c ---------------------------------------------------------        
c
c		            8b; Adjust Plan storage 
c
c          3 = reuse to a reservoir
c          5 = reuse to a reservor by tmtn.
c          14= WWSP plan
c 
c rrb 2018/10/11; Add WWSP Plan type
cx        iplntyp1=iplntyp(npS)
cx       if(iplntyp1.eq.3 .or. iplntyp1.eq.5) then
        iplntyp1=iplntyp(npS)
c 
c rrb 2019/04/20; Revise for a WWSP Supply (type 14) and 
c                 WWSP User (type 15)  
cx      if(iplntyp1.eq.3 .or. iplntyp1.eq.5 .or. iplntyp1.eq.14) then
        if(iplntyp1.eq.3 .or. iplntyp1.eq.5 .or. iplntyp1.eq.14 .or.
     1     iplntyp1.eq.15) then
          psto21=psto2(npS)
          psto2(npS)=amax1(psto2(npS)- divact*fac, 0.0) 
          if(iout.eq.1) write(nlog,*) '  PowSeaP;',
     1      nps, psto21, psto2(npS)              
        endif  
c
c rrb 2010/10/09; Revise to treat a spill as a return flow
c         4 is reuse to a diversion,
c         6 is reuse to a diversion transmountain
c        11 is an accounting plan
c				
c rrb 2015/01/16; Do not adjust for qdiv(37 since diversions to
c                 admin plans are not used in calculating
c                 River Divert
        if(iplntyp(npS).eq.4 .or. iplntyp(npS).eq.6 .or. 
     1     iplntyp(npS).eq.11) then 
c
c        
c		        qdiv(36         Water released to the river (report as
c			                      return flow).
c           qdiv(37         Water released to the river (report as
c                           a release (negative diversion) that is
c                           subtracted in outmon.f
   
c rrb 2015/10/10; Correct typo from above
          if(nspill.eq.0) then
            qdiv(36,iscdP) = qdiv(36,iscdP) + divact
          else
            qdiv(36,nspill) = qdiv(36,nspill) + divact 
          endif  

        endif
               
      endif  
C
c _________________________________________________________
c
c rrb 2007/07/03; 
c               Step 9; Adjust monthly or annual plan limitations
      if(iout.eq.1) write(nlog,*) ' PowseaP; ', iopsou(5,l2)
      if(iopsou(5,l2).gt.0) then
        lopr=iopsou(5,l2)
        oprmaxM1=oprmaxM(lopr)
        oprmaxM(lopr)=oprmaxM(lopr) + divact*fac
        OprmaxM2=oprmaxM(lopr)
        
        oprmaxM(lopr)=amin1(oprmaxM(lopr), oprmax(lopr,mon))        
        oprmaxA(lopr)=oprmaxA(lopr) + divact*fac
        oprmaxA(lopr)=amin1(oprmaxA(lopr), oprmax(lopr,13)) 
c        
c rrb 2007/11/29; Reduce the amount diverted at the source
        lrS=iopsou(1,lopr)
        ndS=idivco(1,lrS)
        divCap1=divcap(nds)-divmon(nds)
        Divmon(ndS) = amax1(0.0, divmon(ndS)-divact)
        divCap2=divcap(nds)-divmon(nds)

c       iout=1
        if(iout.eq.1) then
          write(nlog,*) ' PowSeaP; Adjusting Diversion Limits & ',
     1      'Capacity'
          write(nlog,*) ' PowSeaP; ',
     1      lopr, divact, divact*fac, oprmaxM1, oprmaxM2,
     1      ndS, divCap1, divCap2
        endif 
c       iout=0      
      endif
      

C
c _________________________________________________________
c
c		            Step 10; Update 
 120  divo(l2)=divo(l2)+divact
c
c _________________________________________________________
c
c		            Step 10;  Detailed Output

      if(iout.eq.1 .or. (iout.eq.2 .and. iw.eq.ioutiw)) then
        ncallX=ncallX+1
        if(ncallX.eq.1)then
          write(nlog,270) corid(l2), cdestyp, csoutyp, 
     1      ccarry, cTandC, cpuse, cspill
        endif  
c   

        write(nlog,280) '  PowseaP   ', iyrmo(mon),xmonam(mon), idy,
     1    cstaid1, iwx, iw, l2,nr, npS, np2,         
     1    ravcfs1*fac, ravcfs2*fac, ravcfs3*fac, ravcfs4*fac, 
     1    OprmaxM1, OprmaxM2, divact*fac,  iwhy, cwhy
     
        write(nlog,'(20f8.0)') (avail(i)*fac, i=1,5)

      endif
c
c rrb 2014/01/15; Print Qdiv data
      if(ioutQ.gt.0) then
        write(nlog,*) ' '
        write(nlog,*) ' PowSeaP out; Qdiv report'
        write(nlog,'(4x, 39i8)') (j, j=1,39)
c
c rrb 2015/10/10; Additonal output
        if(ioutQ.eq.1 .and. nspill.gt.0) then
          write(nlog,*)' PowseaP; nspill=', nspill, cstaid(nspill)
          write(nlog,'(i5, 39f8.0)')
     1      i, (qdiv(nspill,i)*fac, j=1,39)
        endif
        if(ioutQ.eq.2) then
          do i=1, numsta
            write(nlog,'(i5, 39f8.0)') i, (qdiv(j,i)*fac, j=1,39)
          end do
        endif
      endif      
      
c _________________________________________________________
c
c		            Step 11; Return
      RETURN
c
c _________________________________________________________
c
c               Formats
 111  FORMAT(
     1  '  PowseaP; Can only make a release', /,
     1  'to 1 or all accounts. iopsou(2,l2) = ', i5)
 130  format(
     1  ' PowseaP; Problem in allocating release '/,
     1  '        to accounts ct, relaf, ct-relaf, small2'/,
     1  10x, 20f8.0)
 140  format(/,
     1  ' PowseaP; nr iown nowner(nr+1) nowner(nr) nrown1',/
     1  10x,20i8)
cx 142  format(/,       
cx   1  '  PowResP; Source = Plan'/
cx   1  '   Year  Mon'     
cx   1  '     Psuply1      Divact      Divo     Psuply2',/
cx   1  ' _____ _____', 
cx   1  ' ___________ ___________ ___________ ___________')
cx   
 150  format(           
     1  ' PowseaP; n1, relaf, curown(n1), cursto1, c, ct',/
     1  10x, i8, 20f8.0)
 160  format(
     1  '  PowseaP;n1, relaf, curown(n1),cursto1, c, ct',/
     1  i8, 20f8.0) 
     
 170  format(
     1  '  PowseaP; problem the source type must be a ',/
     1  '           reservoir (2) or plan (7) but from ',/
     1  '           Oprinp.f variable iopsouR(l2) = ',i5)
      
 270  format(/, 
     1  '  PowSeaP (Type 29); Reservoir and or Plan Spill',/
     1  '          Operation Right ID = ', a12,
     1  ' Destination Type = ', a12,
     1  ' Source Type = ', a12, 
     1  ' Carrier (Y/N) = ',a3, ' T&C Plan (Y/N) = ',a3,
     1  ' Reuse Plan (Y/N) = ', a3,' Physical Release (Y/N) =', a3/    
     1  '  PowSeaP     iyr mon   day ID          ',
     1  ' Iter   Iw   l2   nr  npS  np2', 
     1  ' RavCfs1 RavCfs2 RavCfs3 RavCfs4 OprMax1 OprMax2  DIVACT',
     1  '    iwhy Comment',/
     1  ' ___________ ____ ____ ____ ____________', 
     1  ' ____ ____ ____ ____ ____ ____', 
     1  ' _______ _______ _______ _______ _______ _______ _______',
     1  ' _______ __________________________')
      
  280   FORMAT(a12, i5,1x,a4, i5, 1x, a12, 6i5, 7f8.1,
     1   i8, 1x, a48)
cx290   format(100f8.0)
c
c
c _________________________________________________________
c
c               Print warning
 9999 write(6,*) '  Stopped in PowseaP, see the log file (*.log)'
      write(nlog,*) '  Stopped in PowseaP'
      write(6,*) 'Stop 1' 
      call flush(6)
      call exit(1)

      stop 
      end

