# 🚀 VS Code Setup Guide for Raspberry Pi Pico Development

> **Quick setup guide for professional VS Code development environment**

## 📦 **One-Command Setup**

### **Install All Extensions:**
```bash
# Install all required VS Code extensions at once
code --install-extension ms-vscode.cpptools-extension-pack \
     --install-extension ms-vscode.cmake-tools \
     --install-extension marus25.cortex-debug \
     --install-extension ms-vscode.vscode-serial-monitor \
     --install-extension ms-vscode.remote-wsl
```

### **Open Project:**
```bash
# Open with complete workspace configuration
code /path/to/raspberry-pi-pico
```

## ✅ **Verification Checklist**

### **1. Extensions Installed:**
- [ ] C/C++ Extension Pack (IntelliSense, debugging)
- [ ] CMake Tools (build integration)
- [ ] Cortex-Debug (ARM debugging)
- [ ] Serial Monitor (USB communication)
- [ ] Remote WSL (Windows development)

### **2. Workspace Features:**
- [ ] **Ctrl+Shift+P** → "Tasks: Run Task" shows Pico tasks
- [ ] IntelliSense shows Pico SDK functions
- [ ] F5 starts ARM debugging session
- [ ] Serial monitor detects `/dev/ttyACM0`

### **3. Development Ready:**
- [ ] Build task compiles successfully
- [ ] Flash task programs device
- [ ] Monitor shows temperature data
- [ ] Debug breakpoints work

## 🎯 **Key Features Enabled**

✅ **One-Click Operations:**
- Build: **Ctrl+Shift+B**
- Flash: **Ctrl+Shift+P** → "Flash Runtime Temperature"
- Debug: **F5**
- Monitor: **Ctrl+Shift+P** → "Monitor Serial"

✅ **Professional Debugging:**
- ARM Cortex-M0+ breakpoint debugging
- Memory and register inspection
- Real-time variable monitoring
- Hardware peripheral overlays

✅ **Zero-Friction Development:**
- Runtime firmware updates
- Integrated serial communication
- Automatic device detection
- Professional workflows

## 🚀 **Ready to Develop!**

Once setup is complete:

1. **Open workspace**: `code raspberry-pi-pico`
2. **Build firmware**: **Ctrl+Shift+P** → "Build Enhanced Temperature"
3. **Flash device**: **Ctrl+Shift+P** → "Flash Runtime Temperature"
4. **Start debugging**: **F5** to debug with breakpoints
5. **Monitor data**: **Ctrl+Shift+P** → "Monitor Serial"

🎉 **VS Code + Claude Code = Professional embedded development!**