import matplotlib.pyplot as plt
import sys

f1 = sys.argv[1]+ sys.argv[2]+".csv" #Vanilla Gibbs
f2 = sys.argv[1] +sys.argv[3]+".csv"
f3 = sys.argv[1] +sys.argv[4]+".csv"
#f4 = sys.argv[1]+"/Vanilla-MCMC_Mod_"+sys.argv[2]+".csv"
#f5 = sys.argv[1] +"/CON-MCMC_HeuristicI_1_"+sys.argv[4]+sys.argv[2]+".csv"


x1=[]
y1=[]
e1=[]
for l1 in open(f1):
    ln = l1.split(',')
    x1.append(float(ln[0]))
    y1.append(float(ln[1]))
    e1.append(float(ln[3]))
    
x2=[]
y2=[]
e2=[]
for l2 in open(f2):
    ln = l2.split(',')
    x2.append(float(ln[0]))
    y2.append(float(ln[1]))
    e2.append(float(ln[3]))

x3=[]
y3=[]
e3=[]
for l3 in open(f3):
    ln = l3.split(',')
    x3.append(float(ln[0]))
    y3.append(float(ln[1]))
    e3.append(float(ln[3]))

# x4=[]
#y4=[]
#e4=[]
#for l4 in open(f4):
#     ln = l4.split(',')
#    y4.append(float(ln[1]))
#    e4.append(float(ln[3]))

#x5=[]
#y5=[]
#e5=[]
#for l5 in open(f5):
#    ln = l5.split(',')
#    x5.append(float(ln[2]))
#    y5.append(float(ln[1]))
#    e5.append(float(ln[3]))


lb = max(min(x1),min(x2),min(x3))#,min(x5))
ub = min(max(x1),max(x2),max(x3))#,max(x5))
#print(max(x5),x5[1],x5[49])

#lb=5
x1_fin = []
y1_fin=[]
e1_fin = []

x2_fin = []
y2_fin=[]
e2_fin = []

x3_fin = []
y3_fin=[]
e3_fin=[]

# x4_fin = []
# y4_fin=[]
# e4_fin=[]

x5_fin = []
y5_fin=[]
e5_fin=[]

lb=3
#ub=12
for i in range(len(x1)):
    if x1[i]>=lb and x1[i]<=ub:
        x1_fin.append(x1[i])
        y1_fin.append(y1[i])
        e1_fin.append(e1[i])

for i in range(len(x2)):
    if x2[i]>=lb and x2[i]<=ub:
        x2_fin.append(x2[i])
        y2_fin.append(y2[i])
        e2_fin.append(e2[i])

for i in range(len(x3)):
    if x3[i]>=lb and x3[i]<=ub:
        x3_fin.append(x3[i])
        y3_fin.append(y3[i])
        e3_fin.append(e3[i])

# for i in range(len(x4)):
#     if x4[i]>=lb and x4[i]<=ub:
#         x4_fin.append(x4[i])
#         y4_fin.append(y4[i])
#         e4_fin.append(e4[i])

#for i in range(len(x5)):
#    if x5[i]>=lb and x5[i]<=ub:
#        x5_fin.append(x5[i])
#        y5_fin.append(y5[i])
#        e5_fin.append(e5[i])
#for i in range(int((ub-lb)/10000)+1):
#	x1_fin[i]=x1_fin[i]/1000
#	x2_fin[i]=x2_fin[i]/1000
#	x3_fin[i]=x3_fin[i]/1000
	#x4_fin=x4_fin/1000
#	x5_fin[i]=x5_fin[i]/1000
#plt.yscale('log')    
plt.plot(x1_fin,y1_fin,'g:',marker='s',markersize=20,linewidth=15.0,label = "Vanilla-MCMC")
plt.plot(x2_fin,y2_fin,'b-.',marker='d',markersize=20,linewidth=15.0, label = "VV_Orbital-MCMC")
plt.plot(x3_fin,y3_fin,'r-.',marker='<',markersize=20,linewidth=15.0, label = "NEC-Orbital-MCMC")
#plt.plot(x4_fin,y4_fin,'m-',marker='>',markersize=18,linewidth=15.0, label = "Vanilla_MOD")
#plt.plot(x5_fin,y5_fin,'k-',marker='*',markersize=18,linewidth=15.0, label = "CON-MCMC("+sys.argv[4]+")")

plt.legend(loc=0,prop={'size':60})

plt.xlabel('Time Taken(s)',fontsize=50, labelpad = 0)
plt.ylabel('KL Div. With True Margs.',fontsize=60, labelpad = 0)

plt.errorbar(x1_fin,y1_fin,yerr=e1_fin,ecolor='g',capsize=12, elinewidth=5)
plt.errorbar(x2_fin,y2_fin,yerr=e2_fin,ecolor='b',capsize=12, elinewidth=5)
plt.errorbar(x3_fin,y3_fin,yerr=e3_fin,ecolor='r',capsize=12, elinewidth=5)
#plt.errorbar(x4_fin,y4_fin,yerr=e4_fin,ecolor='m',capsize=10, elinewidth=5)
#plt.errorbar(x5_fin,y5_fin,yerr=e5_fin,ecolor='k',capsize=10, elinewidth=5)
plt.locator_params(axis='y',nbins=6)
plt.tick_params(axis='x',labelsize=40)
plt.tick_params(axis='y',labelsize=40)

plt.title(sys.argv[5],fontsize=60,y=1.02)
plt.show()
#plt.savefig(sys.argv[5], format='eps', dpi=1000)
exit(0)
