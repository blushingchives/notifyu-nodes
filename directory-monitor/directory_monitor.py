import subprocess
import time
import logging
import requests
import shutil

# --- Configuration ---
CONTAINER_RPC_PORTS = {
    "thornode-1": 26657,
    "thornode-2": 26658,
    "thornode-3": 26659,
}
CATCH_UP_TIMEOUT = 21600  # seconds (6hrs)
CATCH_UP_INTERVAL = 10  # polling interval
SIZE_LIMIT_GB = 150  # GB
CHECK_INTERVAL = 300  # seconds
COMPOSE_PROJECT_DIR = "../"  # Directory with docker-compose.yaml

def get_container_port(container_name):
    return CONTAINER_RPC_PORTS[container_name]
def get_thornode_container_volume_map():
    """Assumes thornode-N containers and volumes are named accordingly."""
    return {
        f"thornode-{i}": f"thornode-volume-{i}"
        for i in range(1, 4)
    }

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")

# --- Helpers ---
def get_total_disk_usage_gb(mount_point: str = "/") -> float:
    """Return *used* space on the given filesystem in GiB."""
    total, used, free = shutil.disk_usage(mount_point)
    return used / (1024**3)
    
def wait_for_thornode_catchup(container_name):
    """Wait until a thornode container is synced."""
    rpc_url = f"http://localhost:{get_container_port(container_name)}"  # Or use Docker DNS

    logging.info(f"⏳ Waiting for {container_name} to catch up...")

    start_time = time.time()
    while time.time() - start_time < CATCH_UP_TIMEOUT:
        try:
            response = requests.get(f"{rpc_url}/status", timeout=5)
            result = response.json()
            catching_up = result["result"]["sync_info"]["catching_up"]
            latest_block = result["result"]["sync_info"]["latest_block_height"]

            logging.info(f"[{container_name}] catching_up={catching_up}, height={latest_block}")

            if not catching_up:
                logging.info(f"✅ {container_name} has caught up.")
                return
        except Exception as e:
            logging.warning(f"⚠️  Waiting on {container_name}: {e}")

        time.sleep(CATCH_UP_INTERVAL)

    raise TimeoutError(f"{container_name} did not catch up in time.")

def run_snapshot():
    """Run the snapshot container."""
    logging.info("📸 Running snapshot container...")
    subprocess.run([
        "docker", "compose", "--profile", "snapshot", "--project-directory", COMPOSE_PROJECT_DIR, "up", "--build", "--force-recreate"
    ], check=True)
    logging.info("✅ Snapshot complete.")

def restart_thornode(container_name, volume_name):
    """Stop, remove volume, restart container and wait for it to catch up."""
    logging.info(f"🔄 Restarting {container_name} with volume {volume_name}...")

    # Stop container
    subprocess.run(["docker", "stop", container_name], check=True)

    # Remove the volume
    logging.info(f"🗑️ Removing volume: {volume_name}")
    subprocess.run(["docker", "volume", "rm", "-f", volume_name], check=True)

    # Recreate container
    subprocess.run([
        "docker", "compose", "--profile", "node", "--project-directory", COMPOSE_PROJECT_DIR, "up", "-d" ,"--build", "--force-recreate", container_name
    ], check=True)

    # Wait for the node to catch up
    wait_for_thornode_catchup(container_name)

# --- Main Monitor Loop ---
def monitor_volumes():
    while True:
        used_gb = get_total_disk_usage_gb()
        logging.info(f"🧮 Total disk usage: {used_gb:.2f} GB")

        if used_gb > SIZE_LIMIT_GB:
            logging.warning(f"🚨 Disk usage exceeded: {used_gb:.2f} GB > {SIZE_LIMIT_GB} GB")

            run_snapshot()

            # container_volume_map = get_thornode_container_volume_map()
            # for container, volume in container_volume_map.items():
            #     try:
            #         restart_thornode(container, volume)
            #     except subprocess.CalledProcessError as e:
            #         logging.error(f"❌ Error restarting {container}: {e}")

        time.sleep(CHECK_INTERVAL)

# --- Entry Point ---
if __name__ == "__main__":
    monitor_volumes()
