//
//  idevice.js
//  StikJIT
//
//  Created by s s on 2025/4/24.
//

async function core_device_proxy_connect_tcp() {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "core_device_proxy_connect_tcp"
    });
}

async function core_device_proxy_get_server_rsd_port(core_device_handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "core_device_proxy_get_server_rsd_port",
        "handle": core_device_handle
    });
}

async function core_device_proxy_create_tcp_adapter(core_device_handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "core_device_proxy_create_tcp_adapter",
        "handle": core_device_handle
    });
}

async function adapter_connect(adapter, port) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "adapter_connect",
        "adapter": adapter,
        "port": port
    });
}

async function xpc_device_new(adapter) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "xpc_device_new",
        "adapter": adapter,
    });
}

async function xpc_device_get_service(handle, service_name) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "xpc_device_get_service",
        "handle": handle,
        "service_name": service_name
    });
}

async function xpc_device_get_info(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "xpc_device_get_info",
        "handle": handle,
    });
}

async function xpc_device_adapter_into_inner(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "xpc_device_adapter_into_inner",
        "handle": handle,
    });
}

async function remote_server_adapter_new(adapter) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "remote_server_adapter_new",
        "adapter": adapter,
    });
}

async function remote_server_adapter_into_inner(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "remote_server_adapter_into_inner",
        "handle": handle,
    });
}

async function process_control_new(server) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "process_control_new",
        "server": server
    });
}

async function process_control_launch_app(handle, bundle_id, env_vars, arguments, start_suspended, kill_existing) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "process_control_launch_app",
        "handle": handle,
        "bundle_id": bundle_id,
        "env_vars": env_vars,
        "arguments": arguments,
        "start_suspended": start_suspended,
        "kill_existing": kill_existing
    });
}

async function process_control_disable_memory_limit(handle, pid) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "process_control_disable_memory_limit",
        "handle": handle,
        "pid": pid
    });
}

async function process_control_kill_app(handle, pid) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "process_control_kill_app",
        "handle": handle,
        "pid": pid
    });
}

async function debug_proxy_adapter_new(adapter) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "debug_proxy_adapter_new",
        "adapter": adapter,
    });
}

async function debug_proxy_send_command(handle, command) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "debug_proxy_send_command",
        "handle": handle,
        "debug_command": command
    });
}

async function springboard_services_connect_tcp() {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "springboard_services_connect_tcp"
    });
}

async function springboard_services_get_icon(client, bundle_id) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "springboard_services_get_icon",
        "client": client,
        "bundle_id": bundle_id
    });
}

async function nsdata_read(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "nsdata_read",
        "handle": handle,
    });
}

async function nsdata_read_range(handle, begin, end) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "nsdata_read_range",
        "handle": handle,
        "begin": begin,
        "end": end
    });
}

async function afc_client_connect_tcp() {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_client_connect_tcp"
    });
}

async function afc_list_directory(handle, path) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_list_directory",
        "handle": handle,
        "path": path
    });
}

async function afc_make_directory(handle, path) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_make_directory",
        "handle": handle,
        "path": path
    });
}

async function afc_remove_path(handle, path) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_remove_path",
        "handle": handle,
        "path": path
    });
}

async function afc_remove_path_and_contents(handle, path) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_remove_path_and_contents",
        "handle": handle,
        "path": path
    });
}

async function afc_rename_path(handle, source, target) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_rename_path",
        "handle": handle,
        "source": source,
        "target": target
    });
}

async function afc_get_file_info(handle, path) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_get_file_info",
        "handle": handle,
        "path": path
    });
}

async function afc_get_device_info(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_get_device_info",
        "handle": handle,
    });
}

async function afc_file_open(handle, path, mode) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_file_open",
        "handle": handle,
        "path": path,
        "mode": mode
    });
}

async function afc_file_close(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_file_close",
        "handle": handle
    });
}

async function afc_file_read(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_file_read",
        "handle": handle
    });
}

async function afc_file_write(handle, data_handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "afc_file_write",
        "handle": handle,
        "data_handle": data_handle
    });
}

// for installation_proxy_callback

var handle_installation_proxy_callback_dict = {"max": 0}
function handle_installation_proxy_js_callback(id, progress) {
    let func = handle_installation_proxy_callback_dict[id];
    if(func) {
        func(progress)
    }
}

function installation_proxy_js_callback_register(callback) {
    let cur = handle_installation_proxy_callback_dict['max']
    handle_installation_proxy_callback_dict['max']++
    handle_installation_proxy_callback_dict[cur] = callback
    return cur;
}

function installation_proxy_js_callback_unregister(id) {
    delete handle_installation_proxy_callback_dict[id]
}

async function installation_proxy_connect_tcp() {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "installation_proxy_connect_tcp"
    });
}

async function installation_proxy_get_apps(client, applicationType, bundleIdentifiers) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "installation_proxy_get_apps",
        "client": client,
        "application_type": applicationType,
        "bundle_identifiers": bundleIdentifiers
    });
}

async function installation_proxy_browse(client, options) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "installation_proxy_browse",
        "client": client,
        "options": options
    });
}

async function installation_proxy_install(client, package_path, options, callback) {
    if(callback) {
        let id = installation_proxy_js_callback_register(callback)
        let ans = await webkit.messageHandlers.ideviceCallback.postMessage({
            "command": "installation_proxy_install",
            "client": client,
            "package_path": package_path,
            "options": options,
            "callback_id": id
        });
        installation_proxy_js_callback_unregister(id)
        return ans;
    } else {
        return await webkit.messageHandlers.ideviceCallback.postMessage({
            "command": "installation_proxy_install",
            "client": client,
            "package_path": package_path,
            "options": options,
            "callback_id": -1
        });
    }
}

async function installation_proxy_upgrade(client, package_path, options, callback) {
    if(callback) {
        let id = installation_proxy_js_callback_register(callback)
        let ans = await webkit.messageHandlers.ideviceCallback.postMessage({
            "command": "installation_proxy_upgrade",
            "client": client,
            "package_path": package_path,
            "options": options,
            "callback_id": id
        });
        installation_proxy_js_callback_unregister(id)
        return ans;
    } else {
        return await webkit.messageHandlers.ideviceCallback.postMessage({
            "command": "installation_proxy_install",
            "client": client,
            "package_path": package_path,
            "options": options,
            "callback_id": -1
        });
    }
}

async function installation_proxy_uninstall(client, bundle_id, options, callback) {
    if(callback) {
        let id = installation_proxy_js_callback_register(callback)
        let ans = await webkit.messageHandlers.ideviceCallback.postMessage({
            "command": "installation_proxy_uninstall",
            "client": client,
            "bundle_id": bundle_id,
            "options": options,
            "callback_id": id
        });
        installation_proxy_js_callback_unregister(id)
        return ans;
    } else {
        return await webkit.messageHandlers.ideviceCallback.postMessage({
            "command": "installation_proxy_install",
            "client": client,
            "bundle_id": bundle_id,
            "options": options,
            "callback_id": -1
        });
    }
}

async function amfi_connect_tcp() {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "amfi_connect_tcp"
    });
}

async function amfi_reveal_developer_mode_option_in_ui(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "amfi_reveal_developer_mode_option_in_ui",
        "handle": handle
    });
}

async function amfi_enable_developer_mode(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "amfi_enable_developer_mode",
        "handle": handle
    });
}

async function amfi_accept_developer_mode(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "amfi_accept_developer_mode",
        "handle": handle
    });
}

async function misagent_connect_tcp() {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "misagent_connect_tcp"
    });
}

async function misagent_install(handle, data_handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "misagent_install",
        "handle": handle,
        "data_handle": data_handle
    });
}

async function misagent_remove(handle, profile_id) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "misagent_remove",
        "handle": handle,
        "profile_id": profile_id
    });
}

async function misagent_copy_all(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "misagent_copy_all",
        "handle": handle,
    });
}

async function location_simulation_new(server) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "location_simulation_new",
        "server": server
    });
}

async function location_simulation_clear(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "location_simulation_clear",
        "handle": handle
    });
}

async function location_simulation_set(handle, latitude, longitude) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "location_simulation_set",
        "handle": handle,
        "latitude": latitude,
        "longitude": longitude,
    });
}

// data related, not idevice

async function nsdata_get_size(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "nsdata_get_size",
        "handle": handle,
    });
}

async function nsdata_free(handle) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "nsdata_free",
        "handle": handle,
    });
}

async function nsdata_create(base64Data) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "nsdata_create",
        "base64Data": base64Data,
    });
}

async function local_file_open(path, mode) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "local_file_open",
        "path": path,
        "mode": mode
    });
}

async function local_file_close(file) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "local_file_close",
        "file": file,
    });
}

async function local_file_get_size(file) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "local_file_get_size",
        "file": file,
    });
}

async function local_file_read_chunk(file, offset, length) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "local_file_read_chunk",
        "file": file,
        "offset": offset,
        "length": length
    });
}

async function local_file_write_chunk(file, data, offset) {
    return await webkit.messageHandlers.ideviceCallback.postMessage({
        "command": "local_file_write_chunk",
        "file": file,
        "offset": offset,
        "data": data
    });
}