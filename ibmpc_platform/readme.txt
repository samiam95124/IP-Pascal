******************************** IBM-PC STANDALONE *****************************

Implements IP Pascal as a standalone program under the IBM-PC platform.
A bootstrap loader is given that brings a program off disk and into memory, then
switches modes to 32 bits an executes it.

Provides library implementations to directly run IP programs on the hardware
without an operating system. This is useful for embedded systems using PC 
chipsets, as well as programs that need to take over the entire machine.

To run standalone, we need to use a file system. The default file system is
progressive indexing, as implemented for the VO operating system. We share
the VO file system for standalone use.
