OPENQASM 2.0;
include "qelib1.inc";
qreg q0[6];
x q0[2];
cx q0[1],q0[5];
cx q0[2],q0[5];
ccx q0[1],q0[2],q0[4];
cx q0[3],q0[5];
ccx q0[3],q0[4],q0[5];
ccx q0[1],q0[2],q0[4];
x q0[2];
