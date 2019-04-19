# A customizable and automatic control of fan

In case when onboard fan control system doesn't work right enough this `fan.sh` bash script might help.

Make sure you have `lm-sensors` package installed(i.e. `sudo apt install lm-sensors`) and command `sensors` outputs necessary temperatures. Just edit `fan.sh` bash script, changing necessary configuration(`fan_update_fn` function and configuration variables), and run.
Script infinitely checks temperatures and changes fan's speed level using configured thresholds from variable.

> In case of Lenovo laptop(ThinkPad), to make this script work make sure there's `"/proc/acpi/ibm/fan"` driver and `fan_control` is enabled(i.e. `"options thinkpad_acpi fan_control=1"` exists in `"/etc/modprobe.d/thinkpad_acpi.conf"` file(don't forget to reboot after changing this file))

---

Also, there's a service `fan` file which can be used to set script running as a service.
1. Copy service `fan` file to `"/etc/init.d/fan"`
2. Make a directory `"/opt/fan"`
3. Copy bash script `fan.sh` file to `"/opt/fan/fan.sh"`
4. Run `sudo systemctl daemon-reload` to reload scripts or changes
5. Run `sudo service fan start` to start a service

  * *Optional*: Run `sudo service fan status` to check if service running. It should output a text containg `Active: active (running)` in case of successfull start.
  * *Optional*: Run `sensors` to check current temperatures
  * *Optional*: Run `cat "/proc/acpi/ibm/fan"` to check current speed level of fan
  
If error occurs, it's available to increase verbosity via `fan_8_config` configuration variable and check script's output(in case of service, run `sudo service fan status`)

---

Configuration variables:

| Variable        | Description           | Default value  |
| ------------- |:-------------:| -----:|
| `fan_1_config`      | Temperature thresholds(Tempature Level). Please, check `cat "/proc/acpi/ibm/fan"` which options supports your driver. | `"90 disengaged 85 7 80 6 75 5 70 4 65 3 60 2 55 1 50 0"` |
| `fan_2_config`      | Timeout in seconds between checking temperature(supports float and suffix). Please, check `man sleep`. | `"1"` |
| `fan_3_config`      | Fan driver. | `"/proc/acpi/ibm/fan"` |
| `fan_4_config`      | Timeout of fan switch in miliseconds. | `"2000"` |
| `fan_5_config`      | When not found a threshold: `"0"` ~ switch to `"0"` level, `"1"` ~ switch to minimum threshold and `"2"` ~ switch to "auto" level. | `"1"` |
| `fan_6_config`      | Override timeout of fan switch: `"0"` ~ disable, `"1"` ~ enable. | `"0"` |
| `fan_7_config`      | On exit switch: `"0"` ~ switch to `"auto"`, `"1"` ~ switch to initial and `"2"` ~ do not switch(just exit). | `"0"` |
| `fan_8_config`      | Verbose level: `"0"` ~ no output, `"1"` ~ only errors, `"2"` ~ only switches and `"3"` ~ all output. | `"0"` |

---

Links:
1. [ThinkPad fan wiki](http://www.thinkwiki.org/wiki/How_to_control_fan_speed)
