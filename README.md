# Setup Instructions

### Step 1: Run the Setup Script
To initialize your environment, run the following command:

```bash
chmod +x setup.sh && ./setup.sh
```

---

### Step 2: Run Services as Needed
After completing the setup, you can run any service as required. Here's a quick guide to service behaviors:

- **First-Time Users**:  
  `niiion` may not work initially. Ensure proper setup before using it.

- **Hemi Popstart**:  
  This service may require a restart after setup.

- **Titan Service**:  
  Verify the service functionality post-setup to ensure it's running correctly.

- **BlockMesh & VanaNode**:  
  These services should work seamlessly without any issues.

- **Volara**:  
  Functionality should be tested individually to confirm it’s working as expected.

- **ICN**:  
  Works fine, but I don't use it regularly.

---

### Step 3: For Daily Usage
Run the daily starting script with the following command:

```bash
chmod +x daily.sh && ./daily.sh
```

This script is optimized to start your daily services efficiently.

---

### Notes
- Ensure you have Docker installed and configured correctly.  
- Services like Titan and ICN may require additional validation depending on your use case.  
- If any issues occur, refer to the logs or restart the setup process.

Happy coding! 🚀
