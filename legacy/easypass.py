# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""Easypass
"""

def download_random(wordcount: int, count: int = 1) -> None:
    """Download random"""

    url: str = (
        'http://www.random.org/integers/'
        '?min=1&max=6&base=10&format=plain&rnd=new'
        f'&num={wordcount * count}&col={wordcount}'
    )
    raise NotImplementedError
