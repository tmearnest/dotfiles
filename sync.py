from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from shutil import copyfile
from hashlib import md5
from typing import Iterator

import click


@dataclass
class Dotfile:
    path: Path
    mtime: float = field(init=False)
    size: int = field(init=False)
    hash: str = field(init=False)

    def __post_init__(self):
        self.path = self.path.resolve()

        if self.path.exists():
            self.mtime = self.path.stat().st_mtime
            txt = self.path.read_bytes()
            self.size = len(txt)
            self.hash = md5(txt).hexdigest()
        else:
            self.mtime = 0
            self.size = 0
            self.hash = ''

class DotfilePair:
    repo: Dotfile = field(init=False)
    home: Dotfile = field(init=False)
    def __init__(self, line: str):
        cols = line.split("\t")
        if len(cols) != 2:
            raise ValueError(f"Could not split {line!r} into two columns")

        self.repo = Dotfile(Path()/cols[0])
        self.home = Dotfile(Path.home()/cols[1])


def iter_map(path: Path) -> Iterator[DotfilePair]:
    with path.open() as fp:
        for line in fp:
            if line := line.strip():
                yield DotfilePair(line)


def style_dotfile(df: Dotfile, overwrite: bool=False) -> str:
    if df.path.exists() and overwrite:
        path = click.style(df.path, fg='bright_yellow')
    elif df.path.exists():
        path = click.style(df.path, fg='green')
    else:
        path = click.style(df.path, fg='bright_black')

    if df.mtime > 0:
        left = click.style("[", fg='white')
        right = click.style("]", fg='white')
        sep = click.style("; ", fg='white')
        timestamp = datetime.fromtimestamp(df.mtime).strftime('%Y-%m-%d %H:%M:%S')
        sts = click.style(timestamp, fg='cyan')
        sz = click.style(f"{round(0.001*df.size, 3)}kB", fg='cyan')

        return ''.join((path,left,sts,sep,sz,right))

    return path


def do_copy(msg_str: str, src: Dotfile, dest: Dotfile, dry_run: bool=False) -> None:
    left = click.style("[", fg='white')
    right = click.style("]", fg='white')
    msg = click.style(msg_str, fg='bright_blue')

    src_style = style_dotfile(src)
    dest_style = style_dotfile(dest, overwrite=True)
    mapping = ' '.join((src_style, "->", dest_style))

    msg = left + msg + right + " " + mapping

    if not dry_run:
        dest.path.parent.mkdir(exist_ok=True, parents=True)
        copyfile(src.path, dest.path)

    click.echo(msg)


def report_single(df: Dotfile, pth_color: str, msg_str: str, msg_color: str) -> None:
    pth = click.style(df.path, fg=pth_color)
    left = click.style("[", fg='white')
    right = click.style("]", fg='white')
    msg = click.style(msg_str, fg=msg_color)
    click.echo(left+msg+right+" "+pth)


@click.command()
@click.option("--dry-run/--no-dry-run", default=False, help="Only show changes to be made")
@click.option("--conf-file-map", '-f', type=Path, help="Path to conf file table", default=Path('paths.txt'))
def main(dry_run: bool, conf_file_map: Path) -> None:
    for pair in iter_map(conf_file_map):
        if pair.repo.hash == pair.home.hash:
            report_single(pair.home, "green", "up to date", "cyan")

        elif pair.repo.mtime == pair.home.mtime == 0:
            report_single(pair.home, "bright_black", "missing", "bright_red")

        elif pair.repo.mtime > 0 and pair.home.mtime < pair.repo.mtime:
            do_copy("update $HOME", pair.repo, pair.home, dry_run)

        elif pair.home.mtime > 0 and pair.repo.mtime < pair.home.mtime:
            do_copy("update $PWD", pair.home, pair.repo, dry_run)

        else:
            assert False, 'wat'


if __name__ == '__main__':
    main()
