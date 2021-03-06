// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package linux

import (
	"syscall"
	"fmt"

	"gvisor.googlesource.com/gvisor/pkg/abi/linux"
	"gvisor.googlesource.com/gvisor/pkg/bpf"
	"gvisor.googlesource.com/gvisor/pkg/sentry/arch"
	"gvisor.googlesource.com/gvisor/pkg/sentry/kernel"
	"gvisor.googlesource.com/gvisor/pkg/sentry/usermem"
)

// userSockFprog is equivalent to Linux's struct sock_fprog on amd64.
type userSockFprog struct {
	// Len is the length of the filter in BPF instructions.
	Len uint16

	_ [6]byte // padding for alignment

	// Filter is a user pointer to the struct sock_filter array that makes up
	// the filter program. Filter is a uint64 rather than a usermem.Addr
	// because usermem.Addr is actually uintptr, which is not a fixed-size
	// type, and encoding/binary.Read objects to this.
	Filter uint64
}

// seccomp applies a seccomp policy to the current task.
func seccomp(t *kernel.Task, mode, flags uint64, addr usermem.Addr) error {
	// We only support SECCOMP_SET_MODE_FILTER at the moment.
	if mode != linux.SECCOMP_SET_MODE_FILTER {
		// Unsupported mode.
		return syscall.EINVAL
	}

	tsync := flags&linux.SECCOMP_FILTER_FLAG_TSYNC != 0

	// The only flag we support now is SECCOMP_FILTER_FLAG_TSYNC.
	if flags&^linux.SECCOMP_FILTER_FLAG_TSYNC != 0 {
		// Unsupported flag.
		return syscall.EINVAL
	}

	var fprog userSockFprog
	if _, err := t.CopyIn(addr, &fprog); err != nil {
		return err
	}
	filter := make([]linux.BPFInstruction, int(fprog.Len))
	if _, err := t.CopyIn(usermem.Addr(fprog.Filter), &filter); err != nil {
		return err
	}
	compiledFilter, err := bpf.Compile(filter)
	if err != nil {
		t.Debugf("Invalid seccomp-bpf filter: %v", err)
		return syscall.EINVAL
	}

	err = t.AppendSyscallFilter(compiledFilter)
	if err == nil && tsync {
		// Now we must copy this seccomp program to all other threads.
		err = t.SyncSyscallFiltersToThreadGroup()
	}
	return err
}

// Seccomp implements linux syscall seccomp(2).
func Seccomp(t *kernel.Task, args arch.SyscallArguments) (uintptr, *kernel.SyscallControl, error) {
	fmt.Printf(">>> Syscall: seccomp(2)\n")
	return 0, nil, seccomp(t, args[0].Uint64(), args[1].Uint64(), args[2].Pointer())
}
