function raw = get_wdbc(cfg)
%GET_WDBC Atsisiunčia UCI WDBC failus į data/raw/ ir fiksuoja SHA-256.
%  Plano 1 etapas / 1 lentelė: įvestis — UCI ID 17 (wdbc.data, wdbc.names);
%  jokių tylių pataisymų, jei atsisiuntimas ar tuščias failas.

if nargin < 1
    cfg = config();
end

if ~exist(cfg.paths.raw, 'dir')
    mkdir(cfg.paths.raw);
end

raw.data_path = fullfile(cfg.paths.raw, 'wdbc.data');
raw.names_path = fullfile(cfg.paths.raw, 'wdbc.names');
raw.doi = cfg.meta.doi;
raw.download_date = datestr(now, 31); %#ok<DATST> — R2026a vis dar priima datestr

raw.data_path = download_one(cfg.urls.wdbc_data, raw.data_path);
raw.names_path = download_one(cfg.urls.wdbc_names, raw.names_path);

raw.sha256_data = file_sha256(raw.data_path);
raw.sha256_names = file_sha256(raw.names_path);

fprintf('get_wdbc: wdbc.data SHA-256 = %s\n', raw.sha256_data);
fprintf('get_wdbc: wdbc.names SHA-256 = %s\n', raw.sha256_names);
end

function dest = download_one(url, dest)
if exist(dest, 'file')
    info = dir(dest);
    if info.bytes > 0
        fprintf('get_wdbc: jau yra %s (%d B), pakartotinai nesiunciu.\n', dest, info.bytes);
        return
    end
end
fprintf('get_wdbc: atsisiunciu %s\n', url);
try
    opts = weboptions('Timeout', 60);
    websave(dest, url, opts);
catch ME
    error('get_wdbc: nepavyko atsisiusti %s\n%s', url, ME.message);
end
info = dir(dest);
if isempty(info) || info.bytes == 0
    error('get_wdbc: atsisiustas failas tuscias: %s', dest);
end
end

function h = file_sha256(path)
fid = fopen(path, 'r');
if fid < 0
    error('get_wdbc: nepavyko atidaryti %s SHA-256 skaiciavimui', path);
end
bytes = fread(fid, inf, '*uint8');
fclose(fid);
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(bytes);
digest = typecast(md.digest, 'uint8');
h = lower(sprintf('%02x', digest(:).'));
end
